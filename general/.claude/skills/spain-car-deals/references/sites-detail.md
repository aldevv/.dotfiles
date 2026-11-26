Black Friday is live at Clicars (up to 8,000 EUR off), Autohero (fuel voucher up to 300 EUR) and the Madrid Toyota dealer Kobe Motor (financing required). I found no Black Friday campaign from Flexicar, OcasionPlus, Spoticar, Das WeltAuto or Toyota España nationally. Kavak and Aramisauto don't sell cars in Spain, and I found no trace of Lodgecar. AutoScout24, Clicars and Milanuncios blocked automated browsers, so their filter URLs are NOT TESTED. The other URLs marked "tested" loaded today with the filters applied.

## 1. Search URLs

| Site | Search URL (Madrid, hybrid SUV, 30k cap unless noted) | Tested |
|---|---|---|
| **Coches.net** | `https://www.coches.net/hibrido/4x4/segunda-mano/madrid/?MaxPrice=30000` (4,043 results). Swap `hibrido` for `hibrido_enchufable` (1,551) or `electrico` (300). Toyota only: `https://www.coches.net/toyota/hibrido/4x4/segunda-mano/madrid/?MaxPrice=30000` (618). Nationwide: drop `madrid/` | Yes |
| **Autocasion** | `https://www.autocasion.com/todoterrenos-segunda-mano/madrid/hibrido/precio-hasta-30000` (3,858). Swap `hibrido` for `hibrido-enchufable` (1,626) or `electrico` (305). Nationwide: drop `madrid/` (8,504 hybrid). Madrid auto-adds an "Entrega flexible" filter | Yes |
| **Flexicar** | Only one filter per URL works. `https://www.flexicar.es/combustible-hibrido-no-enchufable/carroceria-suv-4x4/segunda-mano/` (2,977 hybrid SUVs), then add price and province in the UI. Other landing pages: `/combustible-hibrido-enchufable/`, `/combustible-electrico/`, `/coches-madrid/`, `/coches-30000/` (each followed by `segunda-mano/`). Combined fuel + body + province paths return 404 | Yes |
| **Toyota Ocasión** | `https://www.toyota.es/coches-segunda-mano/suv` (1,965 results, "desde 24 meses de garantía"), `/hybrid`, `/madrid` (821). The price slider goes up to 30,000 EUR and there's a 30/60 km radius filter. `/madrid/suv` is a 404 | Yes |
| **Autohero** | `https://www.autohero.com/es/search/?bodyType=suv&fuelType=hybrid&priceMax=30000` (273 results). Sells online nationwide, no Madrid filter needed | Yes |
| **Spoticar** | `https://www.spoticar.es/comprar-coches-de-ocasion/H%C3%ADbrido?page=1&filters%5B0%5D%5Bcategory%5D=suv`. Hybrid filter confirmed; I couldn't confirm the SUV category applied. Also `/eléctrico`, `/Híbrido-enchufable` | Partly |
| **Coches.com** | `https://www.coches.com/coches-segunda-mano/suvs-hibridos.htm`, Madrid: `/coches-ocasion-en-madrid.htm`, then set price in the UI | Yes (fuel + body) |
| **Wallapop** | `https://es.wallapop.com/search?category_id=100&body_type=4X4&max_sale_price=30000&distance_in_km=50`. The fuel param `engine=hybrid` is dropped, so pick Híbrido / Híbrido enchufable in the UI. Location is set in the UI. Useful filters: "Tipo de vendedor: Profesional" and "Garantía mínima de 1 año incluida" | Body + price yes |
| **OcasionPlus** | `https://www.ocasionplus.com/coches-segunda-mano/hibrido` and `/electrico` work nationwide. `/madrid/hibrido` silently redirects to `/madrid`, so add the rest in the UI | Partly |
| **Das WeltAuto** | `https://www.dasweltauto.es/esp/seat/coches-hibridos` (same pattern for `skoda` and `cupra`, plus `coches-electricos`), Madrid dealers: `/esp/concesionarios-en-madrid/madrid`. The site now calls itself the used brand of SEAT, ŠKODA and CUPRA only | Yes |
| **AutoScout24.es** | `https://www.autoscout24.es/lst?atype=C&body=6&fuel=2%2CE&priceto=30000&zip=Madrid&zipr=100&cy=E` | NOT TESTED (403 from every client) |
| **Clicars** | `https://www.clicars.com/coches-segunda-mano-ocasion/madrid` | NOT TESTED (Cloudflare block) |
| **Milanuncios** | `https://www.milanuncios.com/coches-de-segunda-mano-en-madrid/`, filters in the UI | NOT TESTED (captcha) |
| Carwow.es | New cars only, not useful here | Yes |
| Kavak / Aramis / Lodgecar | Kavak: kavak.com/es is a 404 and there's no sign of a Spanish retail business (only a holding company). Aramis Group runs Spain through Clicars. Lodgecar: no trace found | - |

## 2. Terms, pitfalls and Black Friday

| Site | Type | Warranty | Return | Price shown / financing pressure | Fees and pitfalls | Black Friday 2026 |
|---|---|---|---|---|---|---|
| **Toyota Ocasión** (official dealers) | Dealer | 24 to 60 months (12 legal + 12 commercial + any factory time left). Cars under 10 years and 185,000 km | Hybrids: full return within 15 days / 1,000 km. Non-hybrids: exchange only | Normal dealer pricing; dealer promos tend to require Toyota financing | 150-point check, certified km. Toyota Relax extends cover up to 15 years / 250,000 km if serviced in the network | Kobe Motor (Majadahonda), until 28 Nov: 1,000 EUR off RAV4 / Yaris Cross, 1,250 EUR off C-HR / Corolla, plus an emailed bonus (up to 500 EUR on C-HR). Only cars under 5 years and 100,000 km, and only with Toyota Easy/Complet financing. No national campaign found |
| **Flexicar** | Dealer chain | 12 months; 2 years 1,340 EUR, 3 years 1,790 EUR (3-year covers the hybrid battery) | 15 days / 1,000 km, online purchases only | **Worst gap.** Headline price is the financed price; cash is about 2,000 to 2,450 EUR (12 to 15%) higher | Says transfer is included, but OCU complaints report surprise fees of 290 to 500 EUR, pressure to buy a 1,600 EUR warranty, and a lock-in of 24 months before you can repay the loan | Last year's "Black Month" (clearance until 30 Nov) can't be confirmed for 2026 (unverified). Listings show "Remate Final" tags |
| **Clicars** (Aramis Group) | Online dealer | 12 months; the 3-year option adds 1,420 to 2,720 EUR | "100 days / 3,000 km", but only for a serious fault | Financed price about 1,450 EUR (around 10%) below cash | 490 EUR transfer and prep, plus 99 EUR home delivery | "Black Days": up to 8,000 EUR off, ECO/CERO cars from 7,800 EUR. Whether it requires financing isn't stated (unverified) |
| **OcasionPlus** | Dealer chain | 12 months; Premium 600 EUR per year | 15 days / 1,000 km, cars sold with over 15,000 km; refund keeps transfer, prep and transport costs | The "En oferta" price is the financed one; cash is about 1,570 EUR (10%) more, and the financing is minimum 72 months with life insurance | 350 EUR transfer and prep. Older stock (median 2016, 125,000 km) | None found |
| **Autohero** | Online dealer | 12 months / 10,000 km; extendable to 36 months | 21 days / 500 km, full refund | Shows the cash price ("Al contado") | Home delivery 149 to 798 EUR. Reviews mention more wear than the photos showed | Fuel voucher up to 300 EUR off selected cars (not branded as Black Friday) |
| **Spoticar** (Stellantis dealers) | Dealer network | 12 or 24 months on listings, no km limit, up to 36 months (Premium) | 14 days / 1,000 km, refund minus transfer costs (Stellantis &You Spain site) | Shows both prices; financed is about 500 to 1,200 EUR lower at 10.46% APR | Many listings are from dealers far from Madrid (example from Castellón) | Only Spoticar France found |
| **Das WeltAuto** | Dealer network | Up to 24 months (Selección: under 2 years / 30,000 km); 12 months (Oportunidad: 2 to 7 years) | Exchange or refund within 15 days / 1,000 km; you pay the agency fees | Normal dealer pricing | Certified km | None found |
| **Coches.net, Autocasion, Coches.com, AutoScout24** | Listing portals, mostly dealers (about 9 in 10 sellers on Coches.net are professional) | Whatever the seller gives | Seller's terms | Many dealer ads show the financed price. Coches.net lets you choose "Tipo de precio: Contado" in the price filter | Judge the seller, not the portal | None found |
| **Wallapop / Milanuncios** | Mostly private sellers | None (private sale) | None | Private prices, on average about 5% below Coches.net | Km tampering (an estimated 15 to 30% of European used cars), fake deposits, fake transfer receipts. Platform protection doesn't cover cars, and you pay 4% ITP | None found |

## 3. Where to check first (best price vs safety)

| # | Site | Why |
|---|---|---|
| 1 | **Toyota Ocasión** (toyota.es plus Madrid dealers such as Kobe Motor) | Your brand. Longest warranty (24 to 60 months, Relax up to 15 years), hybrid return right, certified km. Black Friday offer at Kobe until 28 Nov, but it needs financing |
| 2 | **Coches.net** | Biggest inventory; the tested URL gives 618 Toyota hybrid SUVs in Madrid. Filter by cash price |
| 3 | **Autocasion** | Second-largest portal; clean URLs for hybrid, PHEV and EV SUVs |
| 4 | **Autohero** | Cash price shown, 21-day full-refund return, fuel voucher now |
| 5 | **Clicars** | Black Days up to 8,000 EUR off, but add 490 + 99 EUR and compare the cash price |
| 6 | **Spoticar / Das WeltAuto** | Official-network safety for non-Toyota brands |
| 7 | **Flexicar / OcasionPlus** | Large stock, but compare cash prices only and read the contract |
| Last | **Wallapop / Milanuncios** | Cheapest, riskiest. Only with a DGT report and an independent inspection |

## 4. General Spain buying tips

| Topic | What to know |
|---|---|
| **DGT report** | The full report ("informe completo") costs 8.67 EUR from DGT or the miDGT app, using only the number plate. It shows ITV km readings with dates, charges (embargos, reserva de dominio, leasing), number of owners and recalls. Middlemen charge 17 to 30 EUR. Compare the ITV km with the odometer ([tuio](https://blog.tuio.com/coche/informe-dgt-de-un-vehiculo-2026-tipos-precio-y-como-pedirlo/), [historialvehiculo](https://historialvehiculo.es/informe-dgt/)) |
| **ITV** | Make sure it's valid; dealers like Flexicar hand cars over with ITV passed. The report's ITV history doubles as a km check |
| **ITP (private sale)** | Madrid charges 4% on the higher of the price or the Hacienda table value (Orden HAC/1501/2025). The buyer files modelo 620/621 within 30 working days, plus the DGT transfer fee of 55.70 EUR ([guiafiscal](https://guiafiscal.es/patrimonio/modelo-620-itp-vehiculos/), [gestoria247](https://gestoria247.com/blog/itp-transferencia-vehiculo-madrid)) |
| **Dealer purchase** | No ITP; VAT is in the price (usually under the margin scheme, my understanding, unverified). Budget for the dealer's transfer and prep fee (0 to 490 EUR) |
| **Legal warranty** | From a dealer: 3 years by law, reducible by contract to no less than 1 year. Online/distance purchase: 14-day withdrawal. From a private seller: only a 6-month hidden-defects claim. Someone posing as private but trading regularly counts as a dealer legally ([Comunidad de Madrid](https://www.comunidad.madrid/consumo/coches-segunda-mano-compras-garantia)) |
| **Labels** | Non-plug-in and mild hybrids get **ECO**. EVs get **CERO**. Plug-in hybrids get CERO with 40 km or more of electric range, ECO otherwise (standard DGT rule, DGT page not fetched). Check the label on the DGT report |
| **Madrid ZBE 2026** | Unlabelled cars are fined everywhere. B and C can drive the city but enter Distrito Centro only to park. ECO and CERO enter freely. SER street parking: CERO free or discounted with no time limit; ECO up to 2 hours with a reported 75% discount. On bad-air protocol days only ECO/CERO keep full access ([carwow](https://www.carwow.es/noticias/6443/madrid-2026-restricciones-etiquetas-fin-moratoria), [arval](https://www.arval.es/blog/zbe-madrid-que-coches-pueden-circular)) |
| **Incentives** | MOVES III closed on 1 Jan 2026. Programa Auto+ (RD 609/2026) pays up to 4,500 EUR, CERO cars only, until 31 Dec 2026 or until funds run out. Used cars qualify only if bought from a professional and first registered in 2025 or later (one source says 12 months maximum in the brand's network, conflict unresolved). A regular hybrid (ECO) gets nothing ([RACE](https://www.race.es/plan-moves-coche-segunda-mano), [motor16](https://www.motor16.com/noticias/plan-auto-2030-ayudas-2026/)) |
| **Financing** | Always ask for the cash price in writing. Check APR (TAE), total cost, the early-repayment penalty, and whether the discount is clawed back if you repay early. Be wary of 72 to 120-month loans taken only for the discount |

## Unverified or conflicting

- Flexicar's 2026 Black Month.
- Whether Clicars Black Days requires financing.
- Toyota's hybrid warranty length: its pages say 24, 36, or "24 to 60" months. The newest article says 24 to 60.
- The Auto+ rules for used cars.
- AutoScout24, Clicars and Milanuncios URLs.
- Most fee figures come from a single comparison article ([Dobacar, 16 Oct 2026](https://dobacar.com/blog/clicars-vs-flexicar-vs-ocasionplus)), checked against OCU complaints for Flexicar.

Sources:
- [Flexicar offers](https://www.flexicar.es/coches-ofertas/segunda-mano/)
- [OCU Flexicar complaint (financing)](https://www.ocu.org/reclamar/lista-reclamaciones-publicas/financiaci-C3-B3n-m-C3-A1s-alta-que-prec/f10a3e301b49a19df0)
- [OCU Flexicar complaint (fees)](https://www.ocu.org/reclamar/lista-reclamaciones-publicas/falsedad-y-falta-de-transparen/063fa1dce20e00978e)
- [Toyota seminuevo guarantees](https://www.toyota.es/world-of-toyota/articles-news-events/garantias-compra-vehiculo-seminuevo-toyota)
- [Kobe Motor Black Days](https://kobemotor.es/black-friday-toyota/)
- [Nosolomotor on Clicars](https://www.nosolomotor.es/noticias/black-friday-coches-ocasion-hibrido-busquedas-clicars/20261126083700003463.html)
- [Clicars about](https://www.clicars.com/sobre-nosotros)
- [OcasionPlus opinions](https://www.ocasionplus.com/noticias/opiniones-sobre-ocasionplus/)
- [Autohero FAQ](https://www.autohero.com/es/faq/)
- [Stellantis &You warranties](https://www.stellantisandyou.com/es/descubre-las-garantias-que-ofrece-stellantis-you)
- [Das WeltAuto FAQ](https://www.dasweltauto.es/es/faqs.html)
- [Dobacar Wallapop vs Coches.net](https://dobacar.com/blog/wallapop-vs-cochesnet-vs-autoscout24)
- [Sanchez Berenguer on Wallapop](https://sanchezberenguerabogado.com/comprar-coche-segunda-mano-wallapop/)
- [Kavak España registry](https://www.einforma.com/informacion-empresa/kavak-espana-investments-holdings)
- [Aramis Group](https://en.wikipedia.org/wiki/Aramis_Group)
- [Autopista Black Friday 2026](https://www.autopista.es/noticias-motor/black-friday-coches-2026-todas-marcas-rebajan-sus-precios-hasta-cuanto-puedes-ahorrar_336548_102.html)