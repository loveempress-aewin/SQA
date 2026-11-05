author	: mei yun && lovequeen
date	:
Mon Jul 13 13:27:50 CST 2026 (2026/07/13-13:27:50)

| [[auto]] |

version 1.0

-------------------------------------------------------------------------------

開發筆記 請看
[按我📒📒](./dev-note-tra.md)

-------------------------------------------------------------------------------

# nicee
```bash ================================================================
[root@localhost v1.00]#   ./nicee|g slot
  x = 1~16 : slot 1~16
[root@localhost v1.00]# ./nicee|g slot|cut -d"~" -f 2
16 : slot 1
[root@localhost v1.00]# ./nicee|g slot|cut -d"~" -f 1
  x = 1
[root@localhost v1.00]# ./nicee|g slot|cut -d"~" -f 3
```

# struct
```bash ================================================================
.
├── sample_code
└── sio_drv
```
這是測試的架構 基礎會有這兩包 `sample code`

```bash ================================================================

.
├── ccauto  ####<---- 這就是 自動化測試的項目
├── sample_code
└── sio_drv

[root@localhost L_1949]# loveme --graph aewin 1314
.
├── ccauto
├── csv     #### <---- 這是自動化產生的報告 LOG
├── sample_code
└── sio_drv
```

# niceei\_slot\_param.txt format
這裡說明 `nicee_slot_param.txt` 格式 是經過 驗證後的結果
也是依照 我們原本8片的網卡上的格式 已經加入

- ![#f03c15](https://placehold.co/15x15/f03c15/f03c15.png)
如果網卡沒有到達上限 請自行改變這個檔案的數量

```log ================================================================
R600BL,8,x4,Ver3,2 bypass
R600BL,8,x4,Ver3,2 bypass
R600BL,8,x4,Ver3,2 bypass
R600BL,8,x4,Ver3,2 bypass
R0385C,8,x4,,No bypass.
R0471E,8,x8,,No bypass.
R0471D,8,x8,Ver3,4 bypass
R602CL,8,x4,Ver3,4 bypass
```
1. `No bypass` => `No bypass.` need dot
