# umt-meslekler

Meslek bazli NPC gorev sistemi.

## Desteklenen Meslekler

- `police`
- `ambulance`
- `pizzaria`
- `burgershot1`
- `burgershot2`
- `mechanic1`
- `mechanic2`

## Gorev Tipleri

- `doctor`: yarali NPC tedavisi
- `police`: rastgele ihbar
- `food`: restorandan siparis alip teslimat
- `mechanic`: arizali arac spawn olur, gidip tamir edilir

## Meslek Bazli Konusmalar

- Doktor: isim/yas/semptom/siddet bilgisi ile hasta konusmasi
- Polis: ihbari acan kisi, supheli profili ve sahada supheli replikleri
- Food: mutfak cagrisi, siparis icerigi, musteri teslimat geri bildirimi
- Mechanic: musteri ariza tarifi, aciliyet notu, tamir sonrasi tesekkur

## Ortak Mechanic Gorevi

- `mechanic1` ve `mechanic2` ayni gorev teklifini gorur.
- Gorevi kim once kabul ederse gorev ona atanir.
- Kabul komutu: `/iskabul`
- Teklif suresi `config.lua > Config.SharedMissionGroups` icinden ayarlanir.

## Ortak Burger Gorevi

- `burgershot1` ve `burgershot2` ayni food gorev teklifini gorur.
- Gorevi kim once kabul ederse gorev ona atanir.
- Kabul komutu: `/iskabul`

## Mechanic Anahtar Sistemi

Mechanic gorevinde arac spawn oldugunda gorevi alan oyuncuya otomatik key verilir.

`config.lua > Config.VehicleKeys`:

- `Backend = 'auto'` ile otomatik algilama
- `qb-vehiclekeys` destegi
- `qs-vehiclekeys` destegi
- `custom` event destegi

## Backend Uyumlulugu

- Framework: `qb`, `esx`, `standalone`, `auto`
- Target: `qb-target`, `qtarget`, `ox_target`, `none`, `auto`
- Inventory: `qb`, `esx`, `ox`, `none`, `auto`
- Notify: `qb`, `esx`, `ox`, `native`, `auto`
- Progress: `qb`, `ox`, `native`, `auto`

Target `none` olursa sistem fallback 3D text etkilesim kullanir.

## Kurulum

1. Klasoru resources icine koy.
2. `server.cfg` icine `ensure umt-meslekler` ekle.
3. Kullandigin backend resource'larini acik tut.
