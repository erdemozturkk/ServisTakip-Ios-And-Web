Adım adım GitHub'a yükleme (Windows cmd için):

1) Proje klasörüne git

```cmd
cd C:\Users\Erdem\Desktop\ios\flutter_application_1
```

2) Git başlat ve commit

```cmd
git init
git add .
git commit -m "Initial commit: ServisTakip"
```

3) GitHub'da yeni repo oluştur (web arayüzünden veya gh CLI ile). Örnek gh ile:

```cmd
gh repo create ServisTakip --public --source=. --remote=origin
```

4) Eğer gh kullanmadıysanız uzaktaki repo'yu ekleyin ve push edin

```cmd
git branch -M main
git remote add origin https://github.com/<kullanici_adiniz>/ServisTakip.git
git push -u origin main
```

5) Push sonrası GitHub sayfasına gidip repo içeriğini kontrol edin.

İsterseniz bu komutları sizin için terminalde çalıştırabilirim. `gh` CLI yüklü değilse web arayüzünü kullanmanız gerekecek.
