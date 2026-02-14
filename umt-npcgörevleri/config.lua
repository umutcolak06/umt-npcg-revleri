Config = {}

Config.Debug = false
Config.RequireDuty = true
Config.DespawnSeconds = 5

Config.Framework = 'auto' -- auto | qb | esx | standalone
Config.TargetBackend = 'auto' -- auto | qb-target | qtarget | ox_target | none
Config.InventoryBackend = 'auto' -- auto | qb | ox | esx | none
Config.NotifyBackend = 'auto' -- auto | qb | esx | ox | native
Config.ProgressBackend = 'auto' -- auto | qb | ox | native

Config.VehicleKeys = {
    Enabled = true,
    Backend = 'auto', -- auto | qb | qs | custom | none
    QbEvent = 'vehiclekeys:client:SetOwner',
    QsEvent = 'qs-vehiclekeys:client:AddKeys',
    CustomEvent = '',
}

Config.Reward = {
    DefaultType = 'money', -- money | item
    DefaultAccount = 'cash', -- qb: cash/bank, esx: money/bank
}

Config.Dispatch = {
    Enabled = false,
    ClientEvent = 'umt_meslekler:client:dispatch',
}

Config.PolicePunishment = {
    TriggerEvents = false,
    JailEvent = '',
    CommunityEvent = '',
    JailMinutes = 20,
    CommunityMinutes = 30,
}

Config.JobAliases = {
    ems = { 'ambulance' },
    ambulance = { 'ems' },
}

Config.FoodDropoffs = {
    vector4(-307.49, 643.48, 176.13, 130.31),
    vector4(-245.74, 621.98, 187.81, 161.81),
    vector4(-232.83, 588.22, 190.54, 16.31),
    vector4(-293.7, 600.75, 181.58, 2.99),
    vector4(-339.35, 625.81, 171.36, 46.8),
    vector4(-353.02, 668.44, 169.08, 160.99),
    vector4(-340.38, 668.49, 172.78, 256.07),
    vector4(-400.0, 664.66, 163.83, 0.07),
    vector4(-446.24, 686.4, 153.28, 207.71),
    vector4(-476.6, 647.45, 144.39, 16.31),
    vector4(-523.22, 628.15, 137.97, 286.1),
    vector4(-559.62, 663.66, 145.49, 341.11),
    vector4(-568.53, 664.75, 145.48, 336.97),
    vector4(-564.62, 684.67, 146.63, 202.88),
    vector4(-606.17, 672.24, 151.6, 1.19),
    vector4(-661.61, 679.27, 153.91, 94.8),
    vector4(-700.76, 646.91, 155.38, 351.72),
    vector4(-668.28, 638.88, 149.53, 84.99),
    vector4(-685.94, 596.12, 143.85, 42.01),
    vector4(-704.27, 588.39, 142.28, 4.95),
    vector4(-733.13, 593.53, 142.48, 332.53),
    vector4(-753.43, 620.31, 142.85, 284.55),
    vector4(-765.79, 650.53, 145.7, 306.44),
    vector4(-852.89, 694.97, 148.99, 1.79),
    vector4(-884.56, 699.51, 151.27, 94.06),
    vector4(-908.62, 693.66, 151.44, 356.2),
    vector4(-931.44, 690.89, 153.47, 0.6),
    vector4(-1065.02, 726.71, 165.47, 14.34),
    vector4(-1056.4, 761.38, 167.32, 290.07),
    vector4(-998.68, 768.72, 171.58, 292.18),
    vector4(-972.16, 752.18, 176.38, 48.5),
    vector4(-999.59, 817.02, 173.05, 224.14),
    vector4(-962.68, 814.37, 177.76, 179.32),
    vector4(-931.89, 809.14, 184.78, 180.2),
    vector4(-912.28, 777.06, 187.1, 359.67),
    vector4(-867.25, 784.65, 191.93, 2.42),
    vector4(-823.92, 805.8, 202.78, 21.53),
    vector4(-747.34, 808.1, 215.15, 283.63),
    vector4(-884.14, -1072.51, 2.53, 27.84),
    vector4(-863.88, -1100.99, 6.45, 120.13),
    vector4(-869.13, -1105.4, 2.49, 207.63),
    vector4(-884.17, -1082.03, 2.53, 127.58),
    vector4(-921.59, -1095.25, 2.15, 300.54),
    vector4(-943.24, -1075.35, 2.75, 212.77),
    vector4(-946.83, -1051.41, 2.35, 297.19),
    vector4(-952.44, -1077.55, 2.67, 206.82),
    vector4(-948.43, -1107.53, 2.17, 128.15),
    vector4(-959.77, -1109.83, 2.15, 23.4),
    vector4(-970.23, -1092.97, 2.15, 208.93),
    vector4(-978.03, -1108.35, 2.15, 32.06),
    vector4(-970.44, -1121.01, 2.17, 118.11),
    vector4(-991.75, -1103.41, 2.15, 210.1),
    vector4(-985.87, -1121.64, 4.55, 119.23),
    vector4(-1031.91, -1109.43, 2.16, 304.0),
    vector4(-1024.36, -1139.94, 2.75, 23.79),
    vector4(-1040.54, -1135.86, 2.16, 218.39),
    vector4(-1034.44, -1147.1, 2.16, 29.67),
    vector4(-1045.86, -1159.81, 2.16, 40.83),
    vector4(-1063.53, -1160.33, 2.75, 27.88),
    vector4(-1082.82, -1139.35, 2.16, 222.44),
    vector4(-1067.91, -1163.51, 2.75, 28.26),
    vector4(-1113.92, -1193.94, 2.38, 26.44),
    vector4(-1161.26, -1100.06, 2.22, 35.95),
    vector4(-1122.6, -1089.41, 2.55, 115.52),
    vector4(-1114.08, -1069.3, 2.15, 26.98),
    vector4(-1122.25, -1046.2, 2.15, 209.97),
    vector4(-1104.01, -1059.97, 2.73, 26.6),
    vector4(-1108.76, -1040.8, 2.15, 210.2),
    vector4(-1092.03, -1039.83, 2.15, 215.7),
    vector4(-1068.73, -1049.23, 6.41, 214.96),
    vector4(-1065.79, -1055.44, 6.41, 304.92),
    vector4(-1064.7, -1057.52, 6.41, 297.03),
    vector4(-1063.7, -1055.01, 2.15, 308.71),
    vector4(-1055.95, -1000.76, 2.15, 107.82),
    vector4(-1051.21, -1006.6, 6.41, 34.11),
    vector4(-1054.09, -1000.05, 6.41, 123.35),
    vector4(-1055.1, -998.16, 6.41, 123.93),
    vector4(-1041.53, -1025.74, 2.75, 27.99),
    vector4(-1022.33, -1023.15, 2.15, 25.65),
    vector4(-1008.46, -1015.4, 2.15, 26.0),
    vector4(-995.48, -967.44, 2.55, 295.98),
    vector4(-948.09, -951.66, 2.15, 110.92)
}

Config.SharedMissionGroups = {
    {
        Id = 'mechanic_team',
        Label = 'Mechanic Ortak',
        Jobs = { 'mechanic1', 'mechanic2' },
        OfferDurationSeconds = 45,
    },
    {
        Id = 'burgershot_team',
        Label = 'Burger Ortak',
        Jobs = { 'burgershot1', 'burgershot2' },
        OfferDurationSeconds = 40,
    }
}

Config.Jobs = {
    police = {
        Type = 'police',
        Label = 'Polis',
        IntervalMinutes = { 5, 10 },
        Reward = { type = 'money', account = 'cash', min = 250, max = 450 },
        RequiredAce = nil,
        PedModels = { 'g_m_y_lost_01', 'g_m_y_ballaeast_01', 'g_m_y_famdnf_01' },
        Types = { 'stolen_vehicle', 'murder_suspect', 'wanted_street' },
        Locations = {
            vector4(-1277.4, -888.89, 11.32, 156.86),
            vector4(-920.18, -2203.56, 7.11, 277.8),
            vector4(989.59, -2259.05, 30.52, 263.02),
            vector4(418.65, -648.15, 28.5, 182.2),
            vector4(94.34, -334.25, 43.67, 70.43),
            vector4(-447.05, 6143.1, 31.48, 277.65),
            vector4(2413.42, 4993.4, 46.29, 134.12),
            vector4(1168.26, -737.97, 57.19, 254.03),
            vector4(1055.97, -2462.53, 29.0, 350.7),
            vector4(875.67, -3093.72, 5.9, 264.89),
            vector4(1243.74, -3266.26, 5.6, 264.07),
            vector4(171.29, -3033.97, 5.79, 264.07),
            vector4(-420.81, -2707.13, 6.0, 208.74),
            vector4(-1386.51, -1082.49, 4.26, 310.26),
            vector4(-1506.41, -1340.37, 2.13, 178.03),
            vector4(-3021.69, 123.52, 11.61, 129.93),
            vector4(-320.37, 638.19, 173.48, 136.04)
        },
        Vehicles = { 'asea', 'blista', 'futo' },
        PoliceDialogue = {
            SuspectNames = { 'Logan', 'Ethan', 'Noah', 'Mason', 'Aiden', 'Lucas', 'Dylan', 'Cole' },
            CallerNames = { 'Emma', 'Olivia', 'Sophia', 'Ava', 'Mia', 'Lily', 'Chloe', 'Nora' },
            WitnessLines = {
                'Supheli cok agresif gorunuyordu.',
                'Kirmizi ustu ve koyu pantolon vardi.',
                'Elinde bicak gordugumu saniyorum.',
                'Aracla hizla uzaklasti, plaka secemedim.'
            },
            SuspectLines = {
                'Benden uzak dur! Bana tuzak kuruyorsunuz.',
                'Bir sey yapmadim, ustume gelmeyin.',
                'Cekilin yoldan, kacmam lazim!',
                'Beni yakalayamazsiniz!'
            }
        }
    },

    ambulance = {
        Type = 'doctor',
        Label = 'Doktor',
        IntervalMinutes = { 5, 10 },
        Reward = { type = 'money', account = 'cash', min = 220, max = 400 },
        RequiredAce = nil,
        PedModels = { 'a_m_m_skater_01', 'a_m_y_business_01', 'a_f_y_business_01' },
        DoctorDialogue = {
            Names = {
                'Alex',
                'Jordan',
                'Taylor',
                'Morgan',
                'Casey',
                'Riley',
                'Parker',
                'Cameron'
            },
            BodyParts = {
                'Bacagim',
                'Kolum',
                'Basim',
                'Sirtim',
                'Omzum'
            },
            Incidents = {
                'merdivenden dustum',
                'arac carpti',
                'kavga sirasinda darbe aldim',
                'yuk tasirken sakatlandim',
                'motordan dusup yaralandim'
            },
            Symptoms = {
                'basim donuyor',
                'elim ayagim titriyor',
                'gozum karariyor',
                'nefes almakta zorlaniyorum',
                'dayanilmaz bir agri var'
            },
            Severity = {
                'hafif',
                'orta',
                'ciddi'
            },
            Openings = {
                'Doktor, ben %s. Gercekten iyi degilim.',
                'Doktor, adim %s. Beni bir kontrol eder misin?',
                'Doktor, ben %s... cok kotu hissediyorum.'
            },
            Anxiety = {
                'Cok korktum doktor, durumum ciddi mi?',
                'Boyle kalir miyim diye panik oldum.',
                'Lutfen acik konus, kotu bir sey var mi?'
            },
            DoctorReplies = {
                'Tamam, yanindayim. Once sakin bir sekilde kontrol edecegim.',
                'Nefesini duzenle, seni dinliyorum ve hizlica mudahale edecegim.',
                'Panik yapma, su an guvendesin. Tedavine basliyorum.'
            },
            Closings = {
                'Tesekkur ederim doktor, gercekten rahatladim.',
                'Iyi ki geldin doktor, simdi kendimi daha iyi hissediyorum.',
                'Cok sag ol doktor, agri baya azaldi.'
            }
        },
        Locations = {
            vector4(266.57, -1429.3, 29.33, 107.41),
            vector4(10.83, -1750.48, 29.3, 340.72),
            vector4(622.61, 63.57, 90.01, 340.72),
            vector4(-2318.65, 389.6, 174.47, 340.72),
            vector4(-75.2, 1878.86, 197.13, 340.72),
            vector4(883.21, 2398.17, 50.5, 359.24),
            vector4(1806.07, 3301.57, 42.53, 293.6),
            vector4(2350.87, 4684.74, 35.76, 331.98),
            vector4(-231.13, 6171.21, 31.45, 189.3),
            vector4(-2573.13, 2337.16, 33.06, 231.34),
            vector4(-1386.51, -1082.49, 4.26, 310.26)
        }
    },

    pizzaria = {
        Type = 'food',
        Label = 'Pizzaria',
        IntervalMinutes = { 5, 8 },
        Reward = { type = 'money', account = 'cash', min = 150, max = 300 },
        RequiredAce = nil,
        Dispatcher = vector4(-1193.39, -892.42, 14.00, 300.56),
        DispatcherModel = 's_m_m_linecook',
        DeliveryVehicle = 'faggio',
        DropoffText = '[E] Siparisi Teslim Et',
        Dropoffs = Config.FoodDropoffs,
        FoodDialogue = {
            CustomerNames = { 'Evelyn', 'Hannah', 'Grace', 'Sofia', 'Luna', 'Avery' },
            Orders = { '2x Pepperoni Pizza', '1x Margherita + 1x Cola', 'Aile boyu pizza menusu', '1x Karisik Pizza' },
            PickupLines = {
                'Acil siparis var, sicak cikaralim.',
                'Musteri bekliyor, bunu hizli gotur.',
                'Paket hazir, dikkatli teslim et.'
            },
            DeliveryLines = {
                'Tam zamaninda geldi, tesekkurler!',
                'Siparis eksiksiz, iyi calisma!',
                'Cok hizliydin, sag ol!'
            }
        }
    },

    burgershot1 = {
        Type = 'food',
        Label = 'Burger Shot 1',
        IntervalMinutes = { 5, 9 },
        Reward = { type = 'money', account = 'cash', min = 160, max = 320 },
        RequiredAce = nil,
        Dispatcher = vector4(-1197.50, -892.80, 14.00, 303.00),
        DispatcherModel = 's_m_y_chef_01',
        DeliveryVehicle = 'faggio',
        DropoffText = '[E] Siparisi Teslim Et',
        Dropoffs = Config.FoodDropoffs,
        FoodDialogue = {
            CustomerNames = { 'Harper', 'Scarlett', 'Zoey', 'Stella', 'Madison', 'Aria' },
            Orders = { '2x Cheese Burger Menu', '3x Burger + 2x Fries', '1x Double Burger Menu', 'Aile Boyu Burger Paketi' },
            PickupLines = {
                'Kasadan yeni siparis dustu, bunu al.',
                'Paket tamam, sogutmadan ulastir.',
                'Musteri iki kez aradi, hizli olalim.'
            },
            DeliveryLines = {
                'Mukemmel, tam istedigim gibi.',
                'Cok tesekkurler, harika servis.',
                'Siparis sicak geldi, supersin!'
            }
        }
    },

    burgershot2 = {
        Type = 'food',
        Label = 'Burger Shot 2',
        IntervalMinutes = { 5, 9 },
        Reward = { type = 'money', account = 'cash', min = 160, max = 320 },
        RequiredAce = nil,
        Dispatcher = vector4(-1190.60, -894.80, 14.00, 305.00),
        DispatcherModel = 's_m_y_chef_01',
        DeliveryVehicle = 'faggio',
        DropoffText = '[E] Siparisi Teslim Et',
        Dropoffs = Config.FoodDropoffs,
        FoodDialogue = {
            CustomerNames = { 'Layla', 'Penelope', 'Audrey', 'Naomi', 'Violet', 'Willow' },
            Orders = { '2x Crispy Burger Menu', '1x Mega Burger + Ice Tea', '4x Kids Burger', '1x Double + 1x Classic Menu' },
            PickupLines = {
                'Yogunuz, bu teslimat oncelikli.',
                'Paket yeni kapandi, hemen yola cik.',
                'Adres uzak degil, hizlica birak gel.'
            },
            DeliveryLines = {
                'Emegine saglik, gayet hizliydi.',
                'Musteri memnun, teslimat tamam.',
                'Tam vaktinde oldu, tesekkurler.'
            }
        }
    },

    mechanic1 = {
        Type = 'mechanic',
        Label = 'Mechanic 1',
        IntervalMinutes = { 6, 10 },
        Reward = { type = 'money', account = 'cash', min = 260, max = 500 },
        RequiredAce = nil,
        SpawnLocations = {
            vector4(-211.12, -1325.34, 30.89, 88.21),
            vector4(732.83, -1084.84, 22.17, 178.41),
            vector4(1177.64, 2640.82, 37.75, 1.12),
            vector4(108.24, 6624.67, 31.79, 47.52)
        },
        Vehicles = { 'blista', 'asea', 'sultan', 'baller' },
        MechanicDialogue = {
            OwnerNames = { 'Ryan', 'Connor', 'Blake', 'Tristan', 'Owen', 'Hudson' },
            Issues = {
                'motor aniden stop etti',
                'direksiyon sertlesip kilitlendi',
                'frenler zayifladi',
                'aractan metal sesi geliyor'
            },
            Urgency = {
                'yolda kaldim, acil yardim lazim',
                'arac hic yurumiuyor',
                'tekrar calistirmayi denedim ama olmadi'
            },
            Thanks = {
                'Eline saglik usta, araci toparladin.',
                'Harika is cikardin, cok tesekkurler.',
                'Tam zamaninda geldin, buyuk dertten kurtuldum.'
            }
        }
    },

    mechanic2 = {
        Type = 'mechanic',
        Label = 'Mechanic 2',
        IntervalMinutes = { 6, 10 },
        Reward = { type = 'money', account = 'cash', min = 260, max = 500 },
        RequiredAce = nil,
        SpawnLocations = {
            vector4(548.83, -180.12, 54.49, 256.10),
            vector4(-334.17, -136.26, 39.01, 337.20),
            vector4(-1146.61, -2006.62, 13.18, 322.75),
            vector4(1684.97, 4822.24, 42.01, 95.12)
        },
        Vehicles = { 'blista', 'asea', 'sultan', 'baller' },
        MechanicDialogue = {
            OwnerNames = { 'Caleb', 'Miles', 'Damian', 'Wyatt', 'Asher', 'Jasper' },
            Issues = {
                'hararet bir anda tavana vurdu',
                'vites gecisleri bozuldu',
                'kaputtan duman cikmaya basladi',
                'arac gaz yemiyor'
            },
            Urgency = {
                'gece vardiyasina yetismem lazim',
                'burada guvende hissetmiyorum, cabuk olalim',
                'arac yolda kaldi, cekici cagirmak istemiyorum'
            },
            Thanks = {
                'Ustaligina saglik, sorun cozuldu.',
                'Mukemmel, su an her sey duzeldi.',
                'Cok profesyonelceydi, tesekkur ederim.'
            }
        }
    }
}

Config.Locale = {
    no_permission = 'Bu gorev icin yetkin yok.',
    mission_assigned = '%s gorevi geldi. Haritayi kontrol et.',
    mission_active = 'Aktif gorev bitmeden yeni gorev alamazsin.',
    mission_done = 'Gorev tamamlandi! Odul: $%s',
    mission_done_item = 'Gorev tamamlandi! Odul: %sx %s',
    mission_cancel = 'Gorev iptal edildi.',
    mission_offer = '%s gorevi acildi. Kabul icin /iskabul yaz.',
    mission_offer_expired = 'Teklif suresi doldu.',
    mission_offer_taken = 'Bu gorevi baska biri kabul etti.',
    mission_offer_accepted = 'Gorev kabul edildi, haritayi kontrol et.',
    mission_no_offer = 'Kabul edilecek aktif gorev teklifi yok.',

    doctor_target = 'Yarali ile ilgilen',
    doctor_patient_info = 'Hasta: %s, %s yasinda. %s cok agriyor, %s. Konum: %s',
    doctor_symptom_info = 'Hasta: Agri seviyesi %s, su an %s.',

    police_cuff = 'Kelepcele',
    police_warn = 'Duduk/Uyari',
    police_neutralize = 'Etkisiz hale getirildi',
    police_dead_required = 'Bu secenek icin supheli etkisiz olmali.',
    police_dispatch_info = 'Dispatch: Ihbari acan %s. Not: %s',
    police_suspect_info = 'Supheli: %s. Durum: %s',
    police_suspect_quote = 'Supheli: "%s"',
    police_search = 'Ustunu Ara',
    police_search_progress = 'Ust aramasi yapiliyor...',
    police_search_done = 'Ust aramasi tamamlandi, supheli kontrol altinda.',
    police_search_need_detain = 'Once supheliyi kelepcelemen gerekiyor.',
    police_search_first = 'Once suphelinin ustunu araman gerekiyor.',
    police_send_jail = 'Hapise Gonder',
    police_send_community = 'Kamu Cezasi Ver',
    police_jail_progress = 'Supheli hapise sevk ediliyor...',
    police_community_progress = 'Supheli kamu cezasina sevk ediliyor...',
    police_jail_done = 'Supheli hapse gonderildi.',
    police_community_done = 'Supheliye kamu cezasi verildi.',
    police_surrendered = 'Supheli teslim oldu, komut bekliyor.',
    police_detained = 'Supheli kelepcelendi. Ustunu arayip islemi tamamla.',
    police_fleeing = 'Supheli kacti! Takibe basla.',
    police_fleeing_vehicle = 'Supheli aracla kaciyor!',
    police_attack = 'Supheli saldiriya gecti!',
    police_already_stopped = 'Supheli zaten kontrol altinda.',
    police_exit_vehicle_first = 'Kelepce icin supheliyi once aractan indir.',
    police_lost_suspect = 'Supheli izini kaybettirdi. Gorev sonlandi.',

    food_talk = 'Siparisi Al',
    food_collect = 'Siparis hazirlaniyor...',
    food_deliver = 'Teslimat yapiliyor...',
    food_pickup_info = 'Mutfak: %s',
    food_order_info = 'Siparis: %s | Musteri: %s',
    food_delivery_thanks = 'Musteri (%s): %s',

    mechanic_target = 'Araci Tamir Et',
    mechanic_progress = 'Arac tamir ediliyor...',
    mechanic_key_given = 'Gorev araci anahtari verildi.',
    mechanic_owner_info = 'Musteri: %s | Sorun: %s',
    mechanic_urgency_info = 'Musteri: %s',
    mechanic_thanks = 'Musteri (%s): %s',

    target_missing = 'Target sistemi bulunamadi. 3D text fallback kapali, gorevler durduruldu.',
    backend_detect = 'Framework: %s | Target: %s | Inventory: %s | Keys: %s'
}
