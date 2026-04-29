<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="UTF-8">
  <title>{{ $title }}</title>
</head>
<body style="margin:0;padding:0;background:#f3f7fb;font-family:Arial,Helvetica,sans-serif;color:#17384d;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f3f7fb;padding:30px 12px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#ffffff;border-radius:24px;overflow:hidden;border:1px solid #e2eaf0;">
          <tr>
            <td style="background:linear-gradient(135deg,#233B93,#344FA5,#5E7BDA);padding:28px;text-align:center;color:#ffffff;">
              <div style="font-size:13px;font-weight:700;letter-spacing:2px;">MONOFRAME STUDIO</div>
              <h1 style="margin:12px 0 0;font-size:24px;line-height:1.25;">{{ $title }}</h1>
            </td>
          </tr>

          <tr>
            <td style="padding:30px 28px;text-align:center;">
              <p style="margin:0 0 20px;color:#5b6776;font-size:15px;line-height:1.6;">
                {{ $messageText }}
              </p>

              <div style="display:inline-block;background:#eaf6fb;border-radius:18px;padding:18px 26px;margin:8px 0 20px;">
                <div style="font-size:34px;letter-spacing:8px;font-weight:800;color:#1d3483;">
                  {{ $code }}
                </div>
              </div>

              <p style="margin:0;color:#7b8794;font-size:13px;line-height:1.6;">
                Kode ini berlaku selama {{ $minutes }} menit. Jangan bagikan kode ini kepada siapa pun.
              </p>
            </td>
          </tr>

          <tr>
            <td style="padding:18px 28px;background:#f8fbfd;text-align:center;color:#8a95a3;font-size:12px;">
              Email otomatis dari Monoframe Studio.
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
