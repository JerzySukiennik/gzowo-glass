# do-druku — przymiarka v0.3 (bez elektroniki)

Trzy części + 2 śrubki M2,5×12. Pody są zrośnięte z frontem (v0.2 miało osobne pody, które nie trzymały).
Folder jest kopią `cad/stl/` — źródłem jest `cad/glass.scad`.

| Plik | Szt. | Orientacja na stole | Podpory |
|---|---|---|---|
| `front.stl` | 1 | **tyłem do stołu** (płaska strona, ta od twarzy, w dół) | auto (tree): pod tylnymi połówkami podów i pod noskówkami |
| `temple_r.stl`, `temple_l.stl` | 1+1 | **płasko na boku** (szeroką ścianą do stołu) | trochę pod zagięciem, auto OK |

Ustawienia: PLA, 0,2 mm, **3 ścianki**, wypełnienie 20 %. Skala 1:1 (model dla PD = 62 mm, roboczo).
Front ma 200 mm szerokości — na X1C wchodzi po przekątnej lub wzdłuż X.

## Montaż

1. Zausznik: jego kostka wchodzi między dwie kostki z tyłu poda (dolna jest gwintowana przez śrubę).
2. **M2,5×12 z góry** przez górną kostkę poda, kostkę zausznika, wkręcasz w dolną kostkę. Otwór 2,4 mm — śruba sama nacina gwint w PLA. Zausznik ma się obracać; jak śruba trze, poluzuj ćwierć obrotu.
3. Pokrywek podów nie drukujemy do przymiarki (są w `cad/stl/lid_*.stl`, 4 × M2,5 każda, na potem).

## Zmiany od v0.2 (po pierwszej przymiarce Jurka)

- pody zrośnięte z frontem: zero złącza, zero kołków od spodu, zero dziur w narożnikach
- tylko M2,5×12; otwory 2,4 (gwint) / 2,9 (przelot)
- front wygięty 6° (każda połowa przy mostku), większe otwory na szkła
- zauszniki: jedna gładka krzywa ze zwężeniem
- nic nie wchodzi od spodu

## Co sprawdzić po założeniu

- Czy nadal widać obręcze w polu widzenia → ewentualnie `WRAP` 6 → 9 albo `VD` 18 → 16.
- Noskówki: symetria, czy oprawka opada.
- Zauszniki: ucisk przed uszami (`TEMPLE_SPLAY`), miejsce zgięcia (`TEMPLE_L`), czy hak trzyma za uchem.
