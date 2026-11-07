# App Store Connect — Budgett 1.0

Bu dosyadaki metinler doğrudan App Store Connect alanlarına kopyalanmak üzere hazırlandı.
Karakter sınırları her başlıkta yazıyor ve mevcut uzunluklar sınırın altında.

---

## 1. App Information (dile bağlı olmayan alanlar)

| Alan | Değer |
| --- | --- |
| Bundle ID | `adilemre.budgett` |
| SKU | `budgett-ios-001` |
| Primary Language | Türkçe (tr) |
| Primary Category | **Finance** |
| Secondary Category | **Productivity** |
| Age Rating | **4+** (hiçbir hassas içerik yok) |
| Content Rights | Üçüncü taraf içerik **içermiyor** |
| Pricing | Ücretsiz (uygulama içi satın alma yok) |

---

## 2. Türkçe mağaza sayfası

### Name — 30 karakter sınırı (24 kullanıldı)

```
Budgett — Harcama Takibi
```

### Subtitle — 30 karakter sınırı (27 kullanıldı)

```
Bütçe, abonelik ve hedefler
```

### Promotional Text — 170 karakter sınırı (118 kullanıldı)

> Sürüm yayınlamadan da güncellenebilen tek alandır.

```
Harcamanı iki saniyede kaydet, bütçeni aşmadan ayı bitir. Hesap yok, reklam yok, takip yok — verilerin cihazında kalır.
```

### Keywords — 100 karakter sınırı (93 kullanıldı)

> Virgülle ayır, **boşluk bırakma**. Uygulama adındaki kelimeleri tekrar yazma, Apple zaten indeksliyor.

```
bütçe,harcama,gider,gelir,masraf,abonelik,birikim,hesap,para,finans,cüzdan,takip,plan,kumbara
```

### Description — 4000 karakter sınırı (~1900 kullanıldı)

```
Budgett, paranın nereye gittiğini iki saniyede kaydedip tek bakışta görmen için tasarlandı. Renk kalabalığı yok: sade, siyah-beyaz bir arayüzde yalnızca rakamlar konuşuyor.

HIZLI GİRİŞ
• Hesap makineli tuş takımı — 120+85 yaz, Budgett toplasın
• Sık kullandığın kategoriler ilk sırada
• Cüzdan, etiket, not ve istersen fiş fotoğrafı
• Tek dokunuşla "bunu her ay tekrarla"

AKIŞ
• Gün, hafta, ay, yıl ya da tüm zamanlar
• Güne göre gruplanmış liste; net toplam, gelir ve gider ayrı ayrı
• Arama ve çok kriterli filtre
• Kaydırarak sil, düzenle, kopyala veya analiz dışı bırak
• Yaklaşan ödemeler listenin en başında

ANALİZ
• Dönem özeti ve önceki döneme göre değişim
• Dokunulabilir bar grafik ve ortalama çizgisi
• Kategori kırılımı ve kategori detayına inme
• Günlük ortalama harcama

PLANLAR
• Bütçeler: haftalık, aylık veya yıllık; kategori kapsamı, devir ve eşik uyarısı
• Günlük harcama hakkın ve ay bitene kaç gün kaldığı
• Birikim hedefleri: hedef tutar, tarih ve aylık gereken katkı
• Abonelikler ve tekrar eden ödemeler; aylık gider yükün tek satırda

WIDGET VE KISAYOLLAR
• Ana ekran widget'ları: haftalık harcama, bütçe göstergesi, son hareketler, yaklaşan ödemeler
• Kilit ekranı ve Kontrol Merkezi'nden tek dokunuşla harcama ekle
• Siri ve Kısayollar: "Budgett'e harcama ekle"

VERİN SENDE KALIR
• Hesap açmak yok, kayıt olmak yok, reklam yok, takip yok
• Veriler cihazında saklanır; istersen iCloud ile yalnızca kendi hesabında senkronlanır
• Face ID kilidi ve tutarları gizleyen gizli mod
• CSV veya JSON olarak dışa aktar, yedeğini kendin sakla

AYARLAR
Açık/koyu/sistem teması, para birimi ve gösterim biçimi, haftanın ilk günü, tuş takımı tipi, kuruş gösterimi, gelir takibi, bildirimler, cüzdanlar ve kategoriler.

Budgett tek renkle çalışır: anlam renkten değil, ağırlıktan, boyuttan ve gri tonlarından gelir.
```

### What's New in This Version — 4000 karakter sınırı

```
Budgett'in ilk sürümü.
```

### URL'ler — **senin doldurman gerekiyor**

| Alan | Durum |
| --- | --- |
| Privacy Policy URL | **Zorunlu.** Aşağıdaki hazır metni bir sayfaya koyup linkini gir. |
| Support URL | **Zorunlu.** Basit bir iletişim sayfası ya da e-posta sayfası yeterli. |
| Marketing URL | İsteğe bağlı, boş bırakılabilir. |
| Copyright | Örn. `2026 Adil Emre` — ASC'de ayrı alan, Info.plist'te boş olması sorun değil. |

---

## 3. App Privacy (Data Collection)

App Store Connect ▸ App Privacy ▸ **"Data Not Collected"** seç.

Gerekçe: uygulama hiçbir veriyi kendi sunucusuna göndermiyor. SwiftData deposu cihazda;
iCloud açıldığında veri yalnızca kullanıcının **private CloudKit database**'ine gidiyor ve
bu Apple'ın tanımında "geliştirici tarafından toplanan veri" sayılmıyor. Analitik, reklam
SDK'sı ve üçüncü taraf ağ çağrısı yok.

### Hazır gizlilik politikası metni

> Bir GitHub Pages / Notion / kişisel site sayfasına yapıştırıp URL'ini ASC'ye gir.

```
Budgett Gizlilik Politikası
Son güncelleme: 7 Kasım 2026

Budgett hiçbir kişisel veri toplamaz, saklamaz veya üçüncü taraflarla paylaşmaz.

Verileriniz nerede duruyor
Girdiğiniz tüm işlemler, bütçeler, hedefler, cüzdanlar ve kategoriler yalnızca
cihazınızda saklanır. Budgett'in bir sunucusu veya kullanıcı hesabı yoktur.

iCloud
Ayarlar'dan iCloud senkronizasyonunu açarsanız verileriniz Apple'ın iCloud
altyapısı üzerinden yalnızca sizin özel iCloud hesabınızda saklanır ve
cihazlarınız arasında eşitlenir. Bu veriye uygulama geliştiricisi dâhil hiç kimse
erişemez. Özellik varsayılan olarak kapalıdır.

Fotoğraflar
İşlemlerinize fiş fotoğrafı eklerseniz görsel cihazınızdaki uygulama verisinde
saklanır, hiçbir yere gönderilmez.

Analitik ve reklam
Budgett analitik, çökme raporu veya reklam SDK'sı içermez. Hiçbir kullanım verisi
toplanmaz.

Verilerinizi silmek
Ayarlar ▸ Dışa aktar & yedek ekranından tüm verilerinizi silebilir ya da CSV/JSON
olarak dışa aktarabilirsiniz. Uygulamayı silmek cihazdaki tüm verileri kaldırır.

İletişim
<destek e-postanı yaz>
```

---

## 4. App Review Information

```
Giriş bilgisi gerekmiyor — uygulamanın hesabı yok.

Uygulamayı dolu veriyle görmek için:
Ayarlar ▸ Dışa aktar & yedek ▸ Örnek veri yükle ▸ Ekle

Arayüz Türkçedir (geliştirme bölgesi tr).
Tüm veriler cihazda saklanır; iCloud senkronizasyonu varsayılan olarak kapalıdır.
Uygulama içi satın alma, reklam veya üçüncü taraf hesap bağlama yoktur.
```

**Export Compliance:** `ITSAppUsesNonExemptEncryption = false` anahtarı Info.plist'e eklendi,
bu yüzden her yüklemede şifreleme sorusu sorulmayacak.

---

## 5. Ekran görüntüleri

6.3" iPhone ekranı (**1206 × 2622 px**) — App Store Connect'te `iPhone 6.3" Display` slotu.

| Sıra | Dosya | Başlık |
| --- | --- | --- |
| 1 | `ekran-goruntuleri-6.3/01-akis.png` | Her harcama tek akışta |
| 2 | `ekran-goruntuleri-6.3/02-hizli-giris.png` | İki saniyede kaydet |
| 3 | `ekran-goruntuleri-6.3/03-analiz.png` | Paran nereye gidiyor? |
| 4 | `ekran-goruntuleri-6.3/04-butceler.png` | Bütçeni aşma |
| 5 | `ekran-goruntuleri-6.3/05-hedefler.png` | Hedefine biriktir |
| 6 | `ekran-goruntuleri-6.3/06-abonelikler.png` | Abonelikleri unutma |

`ham-ekran-goruntuleri/` klasöründe aynı ekranların başlıksız, çıplak hâli duruyor —
başka bir tasarım denemek istersen oradan devam edebilirsin.

> **Not:** Apple artık yalnızca tek bir iPhone boyutu istiyor; 6.3" yüklersen diğer iPhone
> boyutları otomatik ölçeklenir. iPad sürümünü de yayınlayacaksan ayrıca 13" iPad ekran
> görüntüsü gerekir.

---

## 6. Yüklemeden önce kalan işler

- [ ] **App Group'u bağla.** Xcode ▸ `budgett` ve `BudgettWidgetsExtension` hedefleri ▸
      Signing & Capabilities ▸ App Groups ▸ `group.adilemre.budgett`.
      Bağlı değilken widget'lar **örnek veriyle** çiziliyor — bu hâliyle yayınlanırsa
      kullanıcıların widget'ında uydurma rakamlar görünür.
- [ ] **iCloud kararını ver.** CloudKit yeteneği açık kalacaksa container listesinde
      `iCloud.adilemre.budgett` **seçili** olmalı. CloudKit istemiyorsan anahtarı elle
      silme, Signing & Capabilities'ten iCloud yeteneğini tamamen kaldır
      (aksi hâlde yükleme hata 90046 ile reddedilir).
- [ ] Privacy Policy ve Support URL'lerini hazırla.
- [ ] Archive ▸ Validate App ▸ Distribute App.

### Bu turda halledilenler

- Yeni ikon (`budgett/AppIcon.icon`, Icon Composer formatı) — eski `AppIcon.appiconset`
  `Supporting/eski-ikon/` altına taşındı.
- Widget uzantısının `CURRENT_PROJECT_VERSION` değeri 1'den 2'ye çekildi; uygulamayla
  eşleşmediği için yükleme uyarısı veriyordu.
- `ITSAppUsesNonExemptEncryption = false` eklendi.
- Örnek verideki üçüncü taraf marka adları (Spotify, Netflix, Migros, İstanbulkart)
  nötr karşılıklarıyla değiştirildi — ekran görüntülerinde marka göstermek inceleme riski.
