const actions = {
  idle: ["待机", "轻微呼吸，尾巴小幅摆动", "我在这里呀"],
  walk: ["行走", "侧身行走素材，四腿交替", "轻轻巡逻中"],
  groom: ["梳毛", "坐姿分层动作，抬爪擦脸", "脸要擦干净"],
  scratch: ["挠抓", "坐姿分层动作，爪子短促摆动", "爪爪活动一下"],
};

const petRig = document.querySelector("#petRig");
const actionName = document.querySelector("#actionName");
const actionNote = document.querySelector("#actionNote");
const bubble = document.querySelector("#bubble");
const buttons = [...document.querySelectorAll("[data-action]")];
let resetTimer = 0;
let switchTimer = 0;
let activeAction = "idle";

function setAction(action) {
  const [name, note, line] = actions[action] || actions.idle;
  actionName.textContent = name;
  actionNote.textContent = note;
  bubble.textContent = line;
  buttons.forEach((button) => button.classList.toggle("active", button.dataset.action === action));
  window.clearTimeout(resetTimer);
  window.clearTimeout(switchTimer);

  if (activeAction === action) {
    petRig.className = `pet-rig action-${action}`;
  } else {
    petRig.className = `pet-rig action-${activeAction} is-switching`;
    switchTimer = window.setTimeout(() => {
      petRig.className = `pet-rig action-${action}`;
      activeAction = action;
    }, 150);
  }

  if (!["idle", "walk"].includes(action)) {
    resetTimer = window.setTimeout(() => setAction("idle"), 1500);
  }
}

buttons.forEach((button) => {
  button.addEventListener("click", () => setAction(button.dataset.action));
});
