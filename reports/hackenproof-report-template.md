# HackenProof Report Template (latihan transisi bounty)

Format standar report bug bounty Web3. Isi semua bagian — report yang jelas = payout lebih cepat.

## 1. Title
`[Severity] [Module] [Bug]` — contoh: `[High] [Withdrawal] Signature malleability allows replay of withdrawal`

## 2. Summary
- Kontrak target + address (testnet/mainnet)
- Satu kalimat: apa bug-nya, kenapa berbahaya
- Scope: file/function yang affected

## 3. Severity
- **Critical**: dana user hilang / drain total / permanent DoS
- **High**: dana terbatas bisa diambil / state rusak permanen
- **Medium**: dana terjebak / kondisi tertentu bisa di-expoit
- **Low**: tidak langsung rugi, tapi risiko (informational, gas grief)

## 4. Vulnerability Details
- Root cause (jelas, dengan referensi baris kode)
- Kenapa ini bug (bukan fitur)

## 5. Proof of Concept (PoC)
- Langkah exploit langkah-by-langkah (siapa, panggil apa, urutan)
- Kode (Foundry test / script) — **harus runnable**
- Hasil: state sebelum vs sesudah

## 6. Impact
- Kuantifikasi: berapa $ / token yang bisa hilang
- Siapa yang terdampak (user, protocol, LP)

## 7. Recommendation / Fix
- Fix minimal (patch kode)
- Fix menyeluruh (desain)

## 8. References
- Kode yang sama di tempat lain (jika ada)
- CVE / audit terkait

## Checklist sebelum submit
- [ ] PoC bisa di-run (forge test) dan PASS
- [ ] Impact kuantifkasi (bukan "bisa rugi")
- [ ] Tidak ada credential/private key bocor di report
- [ ] Severity jujur (jangan overclaim)
- [ ] Bahasa jelas, struktur rapi
