const modelUrl = "live2d/Tianmiao/tianmiao.model3.json";
const motions = [
  ["idle", "待机"],
  ["blink", "眨眼"],
  ["tap", "点击反馈"],
  ["walk", "行走"],
  ["groom", "梳毛"],
  ["scratch", "挠抓"],
];

const statusTitle = document.querySelector("#statusTitle");
const statusNote = document.querySelector("#statusNote");
const bubble = document.querySelector("#bubble");
const canvas = document.querySelector("#live2dCanvas");
const staticPet = document.querySelector(".pet-static");
const buttons = [...document.querySelectorAll("[data-motion]")];
let renderer = null;

function setStatus(title, message) {
  statusTitle.textContent = title;
  bubble.textContent = message;
}

function modelMotions(model) {
  const entries = model?.FileReferences?.Motions || {};
  return new Set(
    motions
      .map(([id]) => id)
      .filter((id) => Array.isArray(entries[id]) && entries[id].some((item) => typeof item.File === "string"))
  );
}

async function boot() {
  try {
    const response = await fetch(modelUrl, { cache: "no-store" });
    if (!response.ok) {
      setStatus("模型待导出", "Live2D 模型待导出");
      return;
    }
    const model = await response.json();
    const available = modelMotions(model);
    if (!window.TianmiaoLive2DRenderer) {
      setStatus("SDK 待接入", "模型已发现，等待接入 Cubism Web SDK");
      return;
    }
    renderer = window.TianmiaoLive2DRenderer.create();
    await renderer.load({ canvas, modelUrl });
    staticPet.hidden = true;
    setStatus("Live2D 已接入", "Live2D 模型已加载");
    buttons.forEach((button) => {
      const motion = button.dataset.motion;
      button.disabled = !available.has(motion);
      button.addEventListener("click", async () => {
        if (!renderer || button.disabled) return;
        buttons.forEach((item) => item.classList.toggle("active", item === button));
        statusNote.textContent = `当前动作：${motion}`;
        bubble.textContent = `${button.textContent}中`;
        await renderer.play(motion);
      });
    });
    if (available.has("idle")) {
      await renderer.play("idle");
    }
  } catch {
    setStatus("模型检查异常", "模型检查失败");
  }
}

boot();
