# do-druku — przymiarka v0.2 (bez elektroniki)

Zestaw do sprawdzenia dopasowania na głowie. Bez pokrywek podów (niepotrzebne do przymiarki)
i bez śrubek: zamiast M2,5 są drukowane kołki. Folder jest kopią `cad/stl/` — źródłem jest `cad/glass.scad`.

| Plik | Szt. | Orientacja na stole | Podpory |
|---|---|---|---|
| `front.stl` | 1 | **tyłem do stołu** (płaska płaszczyzna y=0 w dół, daszek do góry) | tylko pod noskówkami (wystają 4,5 mm za tył), auto-podpory OK |
| `pod_r.stl`, `pod_l.stl` | 1+1 | **na ściance wewnętrznej** (ta z prostokątnym gniazdem), otwarta komora do góry | małe pod kostkami zawiasu z tyłu |
| `temple_r.stl`, `temple_l.stl` | 1+1 | **na boku** (płasko, szeroką ścianą do stołu), hak leży | pod hakiem trochę, auto OK |
| `pegs.stl` | 1 (6 kołków) | leżą płasko, jak wyeksportowane | brak |

Ustawienia: PLA (czarny/ciemnoszary), 0,2 mm, **3 ścianki**, wypełnienie 20 %, bez rafu pod frontem.
Skala: **1:1, nic nie skalować.** Cały model jest policzony dla PD = 62 mm (roboczo).

## Montaż do przymiarki

1. Końcówka daszka (prawa strona frontu) wchodzi w prostokątne gniazdo prawego poda; lewy koniec belki w gniazdo lewego poda. Cztery **krótkie kołki (10 mm)** wciskasz od spodu podów w otwory — wchodzą ciasno, lekko rozwiercić 2 mm wiertłem, jeśli nie chcą.
2. Zausznik: kostka zausznika między dwie kostki poda, **długi kołek (43 mm)** z góry przez wszystkie trzy. Ma się obracać.
3. Jeśli masz jakiekolwiek śrubki M2,5 lub M3 — kołki są tylko zastępstwem.

## Co sprawdzić po założeniu i zapisać (mm)

- Czy noskówki dotykają nosa symetrycznie, czy oprawka opada / uciska.
- Odległość szkieł od rzęs (ma być ≥ 8 mm). Jeśli za blisko → `VD` w SCAD w górę.
- Czy zauszniki uciskają głowę przed uszami (→ `TEMPLE_SPLAY` w górę) albo są luźne (w dół).
- Gdzie zaczyna się zgięcie względem góry ucha (→ `TEMPLE_L`).
- Czy pody nie dotykają skroni.
