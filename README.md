# Veri Bilimi Portföyü: E-ticaret Analitiği, Veri Mühendisliği ve Makine Öğrenmesi

> **English summary:** End-to-end data science portfolio built on Google BigQuery and Python. It covers SQL analytics (sales funnel, category revenue, cohort retention), a tested dbt data warehouse, an A/B test with a two-proportion z-test, an API-to-BigQuery data pipeline, a Looker Studio dashboard, and customer churn prediction with scikit-learn (ROC AUC 0.84 on IBM Telco data). Each project has a PDF case study (in Turkish) and a notebook.

Bu repo, Data Scientist yol haritamda yaptığım projeleri bir araya getiriyor. Her projede bir iş sorusundan başlayıp veriyi çektim, temizledim, analiz ettim ve sonucu bir öneriye dönüştürdüm. Her proje için işverenlere yönelik bir **PDF vaka çalışması** ve kodun bulunduğu bir **notebook** var.

## Projeler

| # | Proje | Soru | Öne çıkan sonuç | Rapor |
|---|---|---|---|---|
| 1 | E-ticaret SQL analizi | Gelir nereden geliyor, müşteriyi nerede kaybediyoruz? | Sepete ekleyenlerin %58'i satın almıyor. 2025 geliri 2024'e göre %42 arttı. | [PDF](eticaret-data-analysis-case-study.pdf) |
| 2 | dbt veri ambarı | Aynı iş kuralını her sorguda yeniden yazmadan tutarlı rapor nasıl üretilir? | 4 model, 13 veri kalitesi testi, `dbt build`: 17/17 başarılı | [PDF](dbt-data-warehouse-project-report.pdf) |
| 3 | Kategori analizi (Python) | Hangi kategoriler hacimle, hangileri fiyatla kazandırıyor? | Outerwear & Coats ve Jeans hem çok satıyor hem pahalı. Intimates en çok satan ama gelirde 10. sırada. | [Notebook](analysis.ipynb) |
| 4 | A/B testi: Cookie Cats | Oyundaki kapı 30. seviyeden 40. seviyeye taşınmalı mı? | Hayır. 7. gün retention %19,02'den %18,20'ye düşüyor (p = 0,0016). | [PDF](ab-testi-cookie-cats-raporu.pdf) |
| 5 | API veri hattı | Dış bir kaynaktan veri nasıl otomatik olarak ambara alınır? | Open-Meteo API'sinden 731 günlük İstanbul hava verisi BigQuery'ye yüklendi | [Notebook](weather_api_pipeline.ipynb) |
| 6 | Churn tahmini | Hangi müşteri bizi bırakacak? | Gerçek veride ROC AUC **0,84**. Sentetik veride sinyal olmadığı tespit edildi. | [PDF](churn-tahmini-raporu.pdf) |

2, 3, 4 ve 5. projelerin tamamı için ayrıca bir özet rapor var: [Modül 2 proje raporu](project-report.pdf).

---

## 1. E-ticaret SQL analizi

**Veri:** `bigquery-public-data.thelook_ecommerce` (Google'ın yayınladığı sentetik moda e-ticaret verisi). Kullanılan tablolar: `orders`, `order_items`, `products`, `events`, `users`.

**İş kuralı:** İptal ve iade edilen kalemler gelire sayılmaz. Satışların yaklaşık %25'i bu yüzden gelire dönüşmüyor (~%15 iptal, ~%10 iade) ve bu oran tüm kategorilerde benzer.

**Satış hunisi (tekil oturum):**

| Adım | Oturum | Bir önceki adımdan dönüşüm |
|---|---|---|
| Ürün görüntüleme | 681.412 | – |
| Sepete ekleme | 431.105 | %63,3 |
| Satın alma | 181.412 | %42,1 |

**Bulgular:**
- En büyük kayıp sepet → satın alma adımında. Sepete ekleyen oturumların %58'i satın almıyor.
- Dönüşüm oranları kanallar arasında neredeyse aynı (±0,4 puan). Yani kaybın nedeni trafik kanalı değil, ödeme sürecinin kendisi. En çok trafiği Email ve Adwords getiriyor.
- Cohort analizinde 30.210 müşterinin ikinci siparişini verdiği görüldü. Google Sheets'te kurulan KPI dashboard'una göre 2025 geliri 2024'e göre %42 arttı (1,30 M $ → 1,84 M $).

**Kullanılan SQL teknikleri:** JOIN, CTE, `COUNT(DISTINCT IF(...))`, `SAFE_DIVIDE`, window fonksiyonları (`LAG`, `ROW_NUMBER`, `FIRST_VALUE`), `DATE_TRUNC` / `DATE_DIFF`, cohort retention.

## 2. dbt veri ambarı

Ham veri **source → staging → mart** katmanlarına ayrıldı. Staging modelleri hafif oldukları için `view`, dashboard'ların sık okuduğu mart modeli `table` olarak kaydedildi.

```
thelook.orders       ──▶ stg_orders
thelook.order_items  ──▶ stg_order_items ──┐
thelook.products     ──▶ stg_products ─────┴──▶ fct_category_revenue
```

- **Testler:** `unique` ve `not_null` testleri yalnızca tablonun gerçek anahtarında. Sipariş durumları ve departmanlar `accepted_values` ile kontrol ediliyor.
- **Sonuç:** `dbt build` → `PASS=17 WARN=0 ERROR=0`
- **Ortam:** dbt Core 1.12 + dbt-bigquery, Google Cloud Shell

## 3. Kategori analizi (Python)

`fct_category_revenue` mart tablosu BigQuery Python istemcisiyle Colab'a çekildi. Kalem başına ortalama fiyat ve kayıp oranı hesaplandı, kategoriler hacim ve fiyata göre dört gruba ayrıldı.

- **Çok satan ve pahalı:** Outerwear & Coats (~148 $), Jeans (~98 $). Gelirin liderleri bunlar.
- **Çok satan ama ucuz:** Intimates (~10.362 kalem, ~33 $). Paket ve çoklu alım kampanyaları sepet tutarını artırabilir.
- **Az satan ama pahalı:** Suits, Clothing Sets. Hedefli reklam ile hacim artırılabilir.

## 4. A/B testi: Cookie Cats

90.189 oyuncu rastgele iki gruba ayrıldı: kapı 30. seviyede (`gate_30`) ve 40. seviyede (`gate_40`).

| Metrik | gate_30 | gate_40 | p-değeri |
|---|---|---|---|
| 1. gün retention | %44,82 | %44,23 | 0,0744 (anlamlı değil) |
| 7. gün retention | %19,02 | %18,20 | 0,0016 (anlamlı) |

- **Yöntem:** İki oranlı z-testi (`statsmodels.proportions_ztest`), %95 güven aralığı, aykırı değer kontrolü (14 günde 49.854 tur oynayan bir kullanıcı)
- **Etki büyüklüğü:** 7. gün retention'da göreli ~%4,3 düşüş, yani her 100.000 oyuncuda bir hafta sonra ~820 kişi daha az
- **Öneri:** Kapı 30. seviyede kalmalı.

## 5. API veri hattı: Open-Meteo → BigQuery

- **Çekme:** `requests` ile Open-Meteo arşiv API'sinden İstanbul'un 2024-2025 günlük sıcaklık ve yağış verisi alındı.
- **Dönüştürme:** JSON yanıtındaki `daily` alanı pandas DataFrame'e çevrildi, tarih tipi düzeltildi, eksik değer kontrol edildi (0) ve günlük ortalama sıcaklık eklendi.
- **Yükleme:** 731 satır `load_table_from_dataframe` ile BigQuery'ye yazıldı.
- **Bulgu:** 2025 yazı neredeyse kuru geçti. Haziran-ağustos toplam yağış 2025'te 7 mm, 2024'te 60 mm.

Bu veri, sonraki adımda zaman serisi tahmini için kullanılacak.

**Dashboard:** dbt mart tablosu Looker Studio'ya bağlandı ([canlı rapor](https://datastudio.google.com/reporting/e629f553-cf77-4198-a619-0fcc0b8566d6)). Toplam net gelir 8,1 M $, Python analiziyle birebir aynı.

## 6. Churn tahmini

Aynı makine öğrenmesi yöntemi iki farklı veride denendi.

| | theLook (sentetik) | IBM Telco (gerçek) |
|---|---|---|
| Müşteri sayısı | 15.647 (son 1 yılda aktif) | 7.043 |
| Churn oranı | %94,1 | %26,5 |
| En iyi ROC AUC | 0,589 | **0,842** |

**theLook:** Veri sızıntısını önlemek için bir **kesim tarihi** kullanıldı. Özellikler 2025-07-01 öncesinden hesaplandı, etiket ise sonraki 90 günden çıkarıldı. Daha zengin özellikler ve Random Forest skoru artırmadı, düşürdü. Sonuç: bu sentetik veride tekrar alışveriş geçmiş davranışla açıklanamıyor.

**Telco:**
- Lojistik regresyon (0,842) Random Forest'ı (0,825) geçti.
- `class_weight='balanced'` ile ayrılacak müşterilerin %78'i yakalanıyor.
- En güçlü churn faktörleri: kısa abonelik süresi, aylık sözleşme ve fiber optik internet. Bunlar permutation importance ve model katsayılarıyla doğrulandı.

**Öğrenilenler:**
- Dengesiz sınıflarda accuracy yanıltıcıdır. İlk model %96 accuracy aldı ama hiçbir geri dönen müşteriyi bulamadı.
- Random Forest'ın varsayılan özellik önemi, sinyal olmasa bile sürekli değişkenleri öne çıkarır. Permutation importance daha güvenilir.

---

## Dosyalar

| Dosya | İçerik |
|---|---|
| `analysis.ipynb` | Kategori analizi, Cookie Cats A/B testi ve theLook churn modelleri |
| `Telco_Customer_Churn.ipynb` | IBM Telco churn modeli |
| `weather_api_pipeline.ipynb` | Open-Meteo → BigQuery veri hattı |
| `*.pdf` | Projelerin vaka çalışması raporları |

## Teknolojiler

**Veri ve altyapı:** Google BigQuery · dbt Core · Google Cloud Shell · Git
**Python:** pandas · scikit-learn · statsmodels · matplotlib · seaborn · requests · Google Colab
**Raporlama:** Looker Studio · Google Sheets

## Çalıştırma

- **SQL sorguları:** [BigQuery konsolunda](https://console.cloud.google.com/bigquery) çalışır. Ücretsiz sandbox yeterli.
- **Notebook'lar:** Google Colab'da açılabilir. BigQuery bağlantısı için kendi Google Cloud proje kimliğinizi `bigquery.Client(project=...)` satırına yazın.
- **Dış veri setleri:** Kaggle'dan indirilir: [Cookie Cats](https://www.kaggle.com/datasets/mursideyarkin/mobile-games-ab-testing-cookie-cats) ve [Telco Customer Churn](https://www.kaggle.com/datasets/blastchar/telco-customer-churn).

## Veri notu

theLook sentetik bir veri setidir ve Google tarafından düzenli olarak yeniden üretilir. Bu yüzden sorgular farklı tarihlerde çalıştırıldığında rakamlar biraz değişebilir.

---

**Zeynep** · [GitHub](https://github.com/zeynep-dmrl)
