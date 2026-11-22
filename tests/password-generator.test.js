/* global QUnit */

function defaultSettings(overrides = {}) {
  return {
    length: 12,
    useLower: true,
    useUpper: true,
    useNum: true,
    startWithLetter: false,
    excludeSimilar: false,
    symbols: "!@#",
    ...overrides
  };
}

const DEFAULT_SYMBOLS = new Set(["!", "@", "#", "$", "%", "&", "*", "-", "_"]);

function resetPasswordUI(app) {
  const doc = app.document;
  doc.getElementById("lengthSlider").value = "12";
  doc.getElementById("lengthDisplay").textContent = "12文字";
  doc.getElementById("useLower").checked = true;
  doc.getElementById("useUpper").checked = true;
  doc.getElementById("useNum").checked = true;
  doc.getElementById("startWithLetter").checked = true;
  doc.getElementById("excludeSimilar").checked = true;
  doc.querySelectorAll(".sym-cb").forEach(checkbox => {
    checkbox.checked = DEFAULT_SYMBOLS.has(checkbox.value);
  });
  app.generatePassword();
}

function resetTheme(app) {
  app.document.body.classList.remove("dark-mode");
  app.updateThemeButton(false);
  app.localStorage.removeItem("passgen_theme");
}

if (location.protocol === "file:") {
  QUnit.test("ローカルHTTPサーバーから実行されている", assert => {
    assert.ok(
      false,
      "file://ではテストできません。READMEの手順でローカルHTTPサーバーを起動してください。"
    );
  });
  QUnit.start();
} else {
  // キャッシュ利用時もloadイベントを取り逃がさないよう、登録後にiframeを読み込む
  const appFrame = document.createElement("iframe");
  const appToggle = document.getElementById("appToggle");
  appFrame.id = "app";
  appFrame.title = "テスト対象のPassGen Custom";
  appToggle.addEventListener("click", () => {
    const isVisible = appFrame.classList.toggle("is-visible");
    appToggle.textContent = isVisible ? "アプリ画面を非表示" : "アプリ画面を表示";
    appToggle.setAttribute("aria-expanded", String(isVisible));
  });
  appFrame.addEventListener("load", event => {
    const app = event.currentTarget.contentWindow;
    appToggle.disabled = false;

    QUnit.module("PassGen Custom", () => {
      QUnit.module("生成ロジック", () => {
        QUnit.test("指定した文字数で生成される", assert => {
          const result = app.createPassword(defaultSettings({ length: 40 }));
          assert.strictEqual(result.password.length, 40, "指定どおり40文字になる");
        });

        QUnit.test("選択した各文字種を最低1文字ずつ含む", assert => {
          const result = app.createPassword(defaultSettings(), () => 0);
          assert.true(/[a-z]/.test(result.password), "小文字を含む");
          assert.true(/[A-Z]/.test(result.password), "大文字を含む");
          assert.true(/[0-9]/.test(result.password), "数字を含む");
          assert.true(/[!@#]/.test(result.password), "記号を含む");
        });

        QUnit.test("先頭を英字に限定できる", assert => {
          const result = app.createPassword(
            defaultSettings({ startWithLetter: true }),
            () => 0
          );
          assert.true(/^[a-zA-Z]/.test(result.password), "先頭が英字になる");
        });

        QUnit.test("紛らわしい文字を除外できる", assert => {
          const result = app.createPassword(
            defaultSettings({ length: 40, excludeSimilar: true })
          );
          assert.false(/[01iIlLoO]/.test(result.password), "紛らわしい文字を含まない");
        });

        QUnit.test("未選択時は小文字を自動的に有効にする", assert => {
          const result = app.createPassword(
            defaultSettings({
              useLower: false,
              useUpper: false,
              useNum: false,
              symbols: ""
            }),
            () => 0
          );
          assert.true(result.settings.useLower, "小文字設定が有効になる");
          assert.true(/^[a-z]+$/.test(result.password), "小文字だけで生成される");
        });
      });

      QUnit.module("画面操作", hooks => {
        hooks.beforeEach(() => {
          resetPasswordUI(app);
          resetTheme(app);
        });

        hooks.afterEach(() => {
          resetPasswordUI(app);
          resetTheme(app);
        });

        QUnit.test("初期設定で12文字のパスワードが表示される", assert => {
          const doc = app.document;
          const selectedSymbols = doc.querySelectorAll(".sym-cb:checked");

          assert.strictEqual(doc.getElementById("lengthSlider").value, "12", "文字数は12");
          assert.strictEqual(doc.getElementById("passwordOutput").value.length, 12, "12文字を表示する");
          assert.true(doc.getElementById("useLower").checked, "小文字が有効");
          assert.true(doc.getElementById("useUpper").checked, "大文字が有効");
          assert.true(doc.getElementById("useNum").checked, "数字が有効");
          assert.true(doc.getElementById("startWithLetter").checked, "先頭英字が有効");
          assert.true(doc.getElementById("excludeSimilar").checked, "類似文字除外が有効");
          assert.strictEqual(selectedSymbols.length, 9, "初期記号は9種類");
        });

        QUnit.test("スライダー変更が文字数表示と生成結果へ反映される", assert => {
          const doc = app.document;
          const slider = doc.getElementById("lengthSlider");

          slider.value = "20";
          slider.dispatchEvent(new app.Event("input", { bubbles: true }));

          assert.strictEqual(doc.getElementById("lengthDisplay").textContent, "20文字", "表示を更新する");
          assert.strictEqual(doc.getElementById("passwordOutput").value.length, 20, "20文字を生成する");
        });

        QUnit.test("増減ボタンで文字数を変更できる", assert => {
          const doc = app.document;
          const increaseButton = doc.querySelector('[aria-label="文字数を増やす"]');
          const decreaseButton = doc.querySelector('[aria-label="文字数を減らす"]');

          increaseButton.click();
          assert.strictEqual(doc.getElementById("lengthSlider").value, "13", "＋ボタンで13文字になる");
          assert.strictEqual(doc.getElementById("passwordOutput").value.length, 13, "13文字を生成する");

          decreaseButton.click();
          assert.strictEqual(doc.getElementById("lengthSlider").value, "12", "−ボタンで12文字に戻る");
        });

        QUnit.test("文字種チェックの変更が生成結果へ反映される", assert => {
          const doc = app.document;
          doc.getElementById("useUpper").click();

          assert.false(doc.getElementById("useUpper").checked, "大文字設定が無効になる");
          assert.false(/[A-Z]/.test(doc.getElementById("passwordOutput").value), "大文字を含まない");
        });

        QUnit.test("先頭英字が有効なときは小文字を自動的に有効にする", assert => {
          const doc = app.document;
          doc.getElementById("useUpper").click();
          doc.getElementById("useLower").click();

          assert.true(doc.getElementById("useLower").checked, "小文字設定が再び有効になる");
          assert.true(/^[a-z]/.test(doc.getElementById("passwordOutput").value), "先頭が小文字になる");
        });

        QUnit.test("記号をすべて選択または解除できる", assert => {
          const doc = app.document;
          const buttons = doc.querySelectorAll(".symbol-actions .mini-link");

          buttons[1].click();
          assert.strictEqual(doc.querySelectorAll(".sym-cb:checked").length, 0, "すべて解除される");

          buttons[0].click();
          assert.strictEqual(doc.querySelectorAll(".sym-cb:checked").length, 21, "21種類すべて選択される");
        });

        QUnit.test("テーマを切り替えられる", assert => {
          const doc = app.document;
          const themeButton = doc.getElementById("themeToggle");

          themeButton.click();
          assert.true(doc.body.classList.contains("dark-mode"), "ダークテーマになる");
          assert.strictEqual(doc.getElementById("themeLabel").textContent, "Light", "切り替え先を表示する");

          themeButton.click();
          assert.false(doc.body.classList.contains("dark-mode"), "ライトテーマに戻る");
          assert.strictEqual(doc.getElementById("themeLabel").textContent, "Dark", "切り替え先を表示する");
        });
      });
    });

    QUnit.start();
  }, { once: true });
  appFrame.src = "../password_gen_custom.html";
  document.body.appendChild(appFrame);
}
