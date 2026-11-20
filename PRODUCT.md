# Product

<!-- impeccable:product-schema 1 -->

## Platform

desktop game (Godot 4.6+, C# + GDScript client in `ClientUI/`)

## Users

Students presenting a school project (TP): the teacher and classmates watch two players race a 5-minute online Boggle round, usually on a laptop or a projector in a lit classroom. It has to impress within seconds and stay readable from the back of the room.

## Product Purpose

Two-player online Boggle. Each player traces words through a 4×4 grid of letter dice by press-drag-release; the server validates words and pushes score updates; the higher score at the end of the timer wins.

## Constraints

- All UI copy is French and stays exactly as written (labels, buttons, messages).
- Press-drag-release tracing and the side "ANNULER" cancel zones keep their behavior.
- No C# or network-layer changes; UI work lives in `.tscn`, `.gd`, fonts and generated assets.
- The client is never told directly whether a word was accepted. The server only sends a score update on a valid guess, so "your score rose shortly after a submit" is the acceptance signal.

## Assets

- Overpass and Overpass Mono (SIL OFL), self-hosted in `ClientUI/assets/fonts/`.
