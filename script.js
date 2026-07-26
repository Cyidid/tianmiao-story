const actions = {
  idle: ["待机", "轻微呼吸和尾巴摆动", "我在这里呀"],
  walk: ["行走", "四腿交替、脚底贴地", "轻轻巡逻中"],
  groom: ["梳毛", "抬爪擦脸，头身联动", "脸要擦干净"],
  scratch: ["挠抓", "后腿节奏，重心下压", "爪爪活动一下"],
  sleep: ["睡眠", "蜷缩感呼吸，安静陪伴", "先眯一小会"],
  roll: ["翻滚", "身体压扁后回弹", "翻个身给你看"],
  hop: ["轻跳", "短促起跳和落地压缩", "收到，跳一下"],
};

const petRig = document.querySelector("#petRig");
const actionName = document.querySelector("#actionName");
const actionNote = document.querySelector("#actionNote");
const bubble = document.querySelector("#bubble");
const buttons = [...document.querySelectorAll("[data-action]")];
let resetTimer = 0;

function setAction(action) {
  const [name, note, line] = actions[action] || actions.idle;
  petRig.className = `pet-rig action-${action}`;
  actionName.textContent = name;
  actionNote.textContent = note;
  bubble.textContent = line;
  buttons.forEach((button) => button.classList.toggle("active", button.dataset.action === action));
  window.clearTimeout(resetTimer);
  if (!["idle", "walk", "sleep"].includes(action)) {
    resetTimer = window.setTimeout(() => setAction("idle"), action === "roll" ? 1600 : 1300);
  }
}

buttons.forEach((button) => {
  button.addEventListener("click", () => setAction(button.dataset.action));
});
