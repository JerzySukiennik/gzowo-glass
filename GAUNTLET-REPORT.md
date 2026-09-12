# Gauntlet: przegląd Gzowo Glass v0.4 (2026-09-12)

Jedna runda, tylko raport (decyzja Jurka). Czterech recenzentów (optyka i geometria: Opus 5, koszyk i elektronika: Sonnet 5), potem świeży, niezależny Critic (Opus 5), który przeliczył 21 twierdzeń liczbowych od zera: 18 zgodnych, 2 błędne poprawki, 1 nieodtwarzalne. Surowe pliki: `work/gauntlet/findings/*.md`, `work/gauntlet/critic.md`.

**Wynik: STOPPED, LIMIT REACHED (jedna runda). Werdykt Critica: CONDITIONAL PASS, 72/100.** Treść recenzji jest w większości prawdziwa, ale brakowało jednej wspólnej listy i rozstrzygnięcia pięciu sprzeczności między plikami. Ta lista jest poniżej, sprzeczności rozstrzygnąłem jako orchestrator, a poprawki wprowadziłem od razu w `cad/glass.scad` jako v0.6.

## Najważniejsze wnioski

1. **Optyka v0.4 dawała obraz, ale okrojony do 44 % pikseli.** Kanały wycięte pod rozmiar OLED-a (22×11), a wiązka na soczewce potrzebuje 38×21 mm. Soczewka stała 91 mm od oka, na złym końcu toru. Do tego trzy odbicia = obraz lustrzany. Werdykt optyki: „ONLY IF".
2. **Nic nie trzymało soczewki, OLED-a ani pierwszego lusterka.** Ich „kieszenie" były wycięte w pustej komorze poda, czyli nie istniały.
3. **Front był trzema osobnymi bryłami**, sklejonymi tylko wspólną płaszczyzną (x = ±66). Slicer scaliłby je przypadkiem albo wcale.
4. **Zauszniki rozchylały się do środka** (znak kąta odwrócony), o 35 mm w głowę przy uszach.
5. Ścianki 0,24–0,6 mm w daszku (za szczelinami na lusterko i szybkę), zawias z 3,5 mm gwintu i śrubą za krótką o 1,5 mm, rowek na kable na 4–6 żył zamiast 9, mostek 4–5 mm w nosie, noskówki obrócone w złą stronę.
6. Koszyk: suma to 140,25 zł, nie „~137"; dodać JST (~4 zł) i termokurczkę (~5 zł); szybka 25×25 wystarczy (wiązka na szybce 16,7×10,2); lusterko „first surface" za 7 zł to realne ryzyko podwójnego odbicia, test latarką po dostawie.
7. Elektronika: jeden XIAO ESP32-S3 Sense wystarcza (I2C na D4/D5, I2S na D0–D2, przycisk na D3, kamera i mikrofon na stałych pinach; dwa porty I2S). Ryzyko: szczyt prądu WiFi + kamera + głośnik przy ~600 mA regulatora; czas pracy ~2 h na 500 mAh, ~4 h na 1000 mAh.

## Rozstrzygnięcia sprzeczności (orchestrator)

| Spór | Decyzja | Uzasadnienie |
|---|---|---|
| Układ optyczny: dwa lusterka (v0.4) czy jedno (optyka §3) | **Jedno.** OLED w daszku na szynie x 60–66, lusterko 45° o oś Y, soczewka w podłodze daszka, szybka pod nią | 100 % pola, 24,7°, obraz nieodwrócony, jedno lusterko taniej. Critic wykrył kolizję soczewki Ø30 z szybką 30×30 w tym układzie; rozwiązane przez szybkę 25×25 i soczewkę na z = 13,4 (przeliczone: przerwa 0,5 mm) |
| Szybka 30×30 vs 25×25 | **25×25×1,1** | Wiązka na szybce 16,7×10,2; 30 mm koliduje z soczewką |
| Liczba lusterek w koszyku | **1 × 30×30** | Wynika z układu |
| Gdzie MAX98357 | **Prawy pod, przy zewnętrznej ściance, na żebrach** | OLED nie jest już w podzie, więc spór o tor ostrości znika |
| `OLED_OFF` 4 vs ≤ 0 | **0 do czasu pomiaru suwmiarką** | Board stoi teraz w daszku między żebrami, nie w podzie; offset ustawiany po dostawie |
| Rowek na 9 żył | **Rowek 5×5 na belce 8 mm** (zamiast 6 mm) | Geometria ma rację, 3,2×3,7 mieści 4–6 żył |
| Zawias (poprawka geometrii #10 dawała 2,3 mm gwintu) | **Kostki 8 / 5 / 2, luzy 0,5, łeb wystaje** | Policzone od nowa: koniec śruby 4 mm w gwintowanej dolnej kostce, 12 mm trzonu wystarcza |
| VD 18 vs skan | **VD 21** | Mostek siedział 4–5 mm w nosie przy z = −12…−15 |
| Kolor OLED | **Biały** | Jurek, 2026-09-12 |

## Lista poprawek (wszystkie wprowadzone w v0.6, chyba że zaznaczono)

| # | Ważność | Co | Stała / moduł w SCAD | Test |
|---|---|---|---|---|
| 1 | S1 | Jeden układ optyczny z jednym lusterkiem, OLED w daszku | `MIR_C`, `LENS_Z`, `OLED_X0/X1`, `COMB`, `BS` | `part="fit"`: duchy OLED, lusterka, soczewki i szybki bez przecięć; po dostawie: pełna ramka 1 px widoczna z 4 stron |
| 2 | S1 | Pozytywne mocowania: szyny OLED, żebra lusterka, kołnierz soczewki w podłodze | `hood_holders()` | Wydruk odwrócony: soczewka trzyma się bez kleju |
| 3 | S1 | Front jako jedna bryła (daszek wchodzi 2 mm w pod, belka 8 mm) | `HOOD_X1 = 68`, `front_solid()` | Eksport STL: jedna powłoka |
| 4 | S1 | Rozchył zauszników na zewnątrz | `rotate([0,0,+s*TEMPLE_SPLAY])`, 15° | Widok z góry ze skanem: zausznik na zewnątrz głowy |
| 5 | S2 | Daszek i pody otwarte od góry, pokrywki na M2,5×12, bez cienkich ścianek za szczelinami | `hood_cavity()`, `lid_hood()`, `lid_pod()` | Ray-cast na STL: każda ścianka ≥ 1,2 mm |
| 6 | S2 | Zawias 8/5/2, luz 0,5, tylna ścianka poda 3 mm, blok kostek 6 mm w pod | `HK_*`, `BACK_W` | Sekcja z = 14: ciągły materiał od kostki do ścianek |
| 7 | S2 | Rowek 5×5 na tylnej ścianie belki 8 mm, koniec przy daszku, przelot do daszka i do prawego poda | `GROOVE`, `BAR_T` | 8 żył 1,5 mm mieści się (3×3 siatka) |
| 8 | S2 | Szybka 25×25, szczelina przez podłogę daszka z fazką (bez ostrza) | `hood_cuts()` | Ray-cast na podłodze przy szczelinie ≥ 1,2 mm |
| 9 | S2 | VD 21, noskówki obrócone w stronę policzka i pochylone | `VD`, `PAD_ANG = +40`, `PAD_TILT = 22` | Przymiarka wydruku: mostek nie dotyka nosa, noskówki płasko |
| 10 | S3 | Przycisk w pokrywce prawego poda (klatka 6,4 mm + otwór Ø4,2) | `lid_pod(1)` | Przełącznik nie wypada, klik wyczuwalny |
| 11 | S3 | Kamera: okno Ø7 + odciążenie Ø10 na wysokości płytki, USB-C w pokrywce lewego poda | `pod_cuts(-1)`, `lid_pod(-1)` | **Do potwierdzenia na realnej płytce** (pozycja złącza i obiektywu) |
| 12 | S3 | Głośnik: kieszeń z kratką 0,8 mm od strony głowy, kanał na kable wychodzi na czole zausznika | `temple_body()` | Przewody przechodzą z poda do kieszeni bez wiercenia |
| 13 | S3 | Kanał wiązki w daszku 22×14 (okno w podłodze), oś na z = 22 | `BEAM_Z`, `hood_cuts()` | Ray-trace z `optics.md` z nowymi aperturami: ≥ 95 % pikseli |
| 14 | v0.7 | Przyciemnienie **przed** szybką (płytka przed daszkiem) zamiast w obręczy | brak | Kontrast HUD:świat rośnie 0,93 → 4,7 |
| 15 | v0.7 | Szybka 70R/30T zamiast 50/50 | koszyk | Kontrast ×2,3 |
| 16 | koszyk | Dopisać JST-PH, termokurczkę; jedno lusterko; szybka 25×25 | `SHOPPING.md` | Suma po zmianie |
| 17 | firmware | Rejestr SSD1306: przy dwóch odbiciach obraz prosty, bez remapu; sprawdzić literą „R" | firmware | „R" czytelne przez szybkę |

## Czego raport nie rozstrzyga (uczciwie)

- Geometria v0.6 (nowy daszek 34 mm wysoki, otwarte komory, pokrywki) **nie była audytowana** przez recenzenta geometrii; to nowa część. Pierwszy test to eksport STL i tabela grubości ścianek, drugi to wydruk samego frontu.
- Wymiary XIAO Sense (wysokość obiektywu, pozycja USB-C) i offset aktywnego pola OLED są z datasheetów i domysłów, nie z pomiaru. Okna w lewym podzie i pokrywce poprawić po dostawie.
- Skan głowy jest w skali roboczej (PD 62). Każdy milimetr błędu PD to ±3 % wszystkich odległości.
- Jasność: HUD czytelny w pomieszczeniu i w cieniu, nie w pełnym słońcu (potrzebny byłby filtr T ≤ 0,005). To ograniczenie SSD1306, nie geometrii.
