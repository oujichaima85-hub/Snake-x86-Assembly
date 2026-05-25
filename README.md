# 🐍 Snake Game — x86 Assembly (8086)

<div align="center">

![Assembly](https://img.shields.io/badge/Assembly-x86_8086-red?style=for-the-badge&logo=assemblyscript&logoColor=white)
![DOSBox](https://img.shields.io/badge/DOSBox-Compatible-green?style=for-the-badge)
![NASM](https://img.shields.io/badge/NASM-Assembler-blue?style=for-the-badge)
![Platform](https://img.shields.io/badge/Platform-DOS-lightgrey?style=for-the-badge)

**A fully functional Snake game written in pure x86 Assembly — no OS, no libraries, just raw machine code.**

</div>

---

## 📌 Overview

This project is a complete implementation of the classic Snake game in **x86 Assembly (8086)**, running under **DOS** via DOSBox. It demonstrates low-level programming concepts including direct video memory manipulation, real-time keyboard input handling, and game loop design — all without any high-level language or framework.

Developed as an academic microprocessor project at **ENSI** (École Nationale des Sciences de l'Informatique).

---

## ✨ Features

| Feature | Description |
|--------|-------------|
| 🎮 Real-time keyboard input | Arrow key handling via BIOS interrupt `INT 16h` |
| 💥 Collision detection | Wall and self-collision detection |
| 🖥️ VGA Graphics | Mode 13h (320×200, 256 colors) rendering |
| 🍎 Random food generation | Pseudo-random seed-based food placement |
| 📊 Score tracking | Live score display during gameplay |
| 🔄 Replay system | Press `R` to restart after Game Over |
| 🎨 Color palette | Custom colors for snake head, body, food and border |

---

## 🛠️ Tech Stack

- **Language** : x86 Assembly (8086)
- **Assembler** : NASM
- **Platform** : DOS (via DOSBox)
- **Video Mode** : VGA Mode 13h (320×200)
- **Input** : BIOS Interrupt INT 16h
- **Output** : Direct video memory + DOS INT 21h

---

## 🚀 How to Run

### Requirements
- [DOSBox](https://www.dosbox.com/download.php?main=1) — DOS emulator
- [NASM](https://www.nasm.us/) — Netwide Assembler

### Step 1 — Assemble
```bash
nasm -f bin snake_full.asm -o snake_full.com
```

### Step 2 — Run with DOSBox
```bash
# Mount your project folder in DOSBox
mount c C:\path\to\project
c:
snake_full.com
```

---

## 🎮 Controls

| Key | Action |
|-----|--------|
| `↑` Arrow | Move Up |
| `↓` Arrow | Move Down |
| `←` Arrow | Move Left |
| `→` Arrow | Move Right |
| `R` | Restart after Game Over |
| `ESC` | Quit |

---

## 🗺️ Game Area

```
┌─────────────────────────────────┐
│  Zone jouable : 60 × 44 blocs   │
│  Taille bloc  : 4×4 pixels      │
│  Résolution   : 320×200 (VGA)   │
└─────────────────────────────────┘
```

---

## 📁 Project Structure

```
Snake-x86-Assembly/
├── snake_full.asm      ← Source code (Assembly)
├── snake_full.com      ← Compiled binary (DOS executable)
└── README.md
```

---

## 🧠 Key Concepts Demonstrated

- **x86 registers** : AX, BX, CX, DX, SI, DI manipulation
- **BIOS interrupts** : INT 10h (video), INT 16h (keyboard), INT 21h (DOS)
- **VGA Mode 13h** : Direct pixel drawing via video memory segment `A000h`
- **Game loop** : Input → Update → Render → Delay
- **Memory management** : Stack, data segment, byte/word addressing

---

## 👩‍💻 Author

**Ouji Chaima** — Computer Engineering Student @ ENSI Tunis

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=flat&logo=linkedin&logoColor=white)](https://linkedin.com/in/ouji-chaima-146254317)
[![GitHub](https://img.shields.io/badge/GitHub-100000?style=flat&logo=github&logoColor=white)](https://github.com/oujichaima85-hub)

---

<div align="center">
<i>Built with ❤️ and raw Assembly — because sometimes, less is more.</i>
</div>
