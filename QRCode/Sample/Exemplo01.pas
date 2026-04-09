uses
  QRCode.Factory,
  QRCode.Types;

// ── Texto simples ──────────────────────────────────────────────────
var LBmp := TQRCode.New
  .SetContent(TQRCode.Text('Olá, Rodrigo!'))
  .GenerateBitmap;

// ── URL ───────────────────────────────────────────────────────────
TQRCode.New
  .SetContent(TQRCode.URL('https://embarcadero.com'))
  .SetErrorLevel(elHigh)
  .GenerateToFile('C:\QR\url.bmp');

// ── E-mail ────────────────────────────────────────────────────────
TQRCode.New
  .SetContent(TQRCode.Email(
    'rodrigo@empresa.com',
    'Contato via QRCode',
    'Olá, vim pelo QRCode!'))
  .GenerateBitmap;

// ── WhatsApp ──────────────────────────────────────────────────────
TQRCode.New
  .SetContent(TQRCode.WhatsApp('+5562999990000', 'Olá!'))
  .GenerateBitmap;

// ── Wi-Fi ─────────────────────────────────────────────────────────
TQRCode.New
  .SetContent(TQRCode.WiFi('MinhaRede', 'senha123', weWPA))
  .GenerateBitmap;

// ── Geolocalização (Goiânia, GO) ──────────────────────────────────
TQRCode.New
  .SetContent(TQRCode.GeoLocation(-16.6869, -49.2648))
  .GenerateBitmap;

// ── vCard ─────────────────────────────────────────────────────────
TQRCode.New
  .SetContent(
    TQRCode.VCard('Rodrigo Souza')
      .SetOrganization('Minha Empresa Ltda')
      .SetPhone('+5562999990000')
      .SetEmail('rodrigo@empresa.com')
      .SetWebsite('https://minhaempresa.com')
  )
  .GenerateBitmap;

// ── PIX ───────────────────────────────────────────────────────────
TQRCode.New
  .SetContent(TQRCode.PIX(
    'rodrigo@empresa.com',  // Chave PIX
    'Rodrigo Souza',        // Nome do recebedor
    'Goiania',              // Cidade
    150.00,                 // Valor (0 = qualquer valor)
    'Pagamento servico',    // Descrição
    'TXN2024001'            // ID da transação
  ))
  .GenerateBitmap;

// ── Renderização customizada ───────────────────────────────────────
var LOptions := TQRRenderOptions.Default;
LOptions.PixelSize := 8;
LOptions.ForeColor := clNavy;
LOptions.BackColor := clYellow;

var LBmp := TQRCode.New
  .SetContent(TQRCode.URL('https://meusite.com.br'))
  .SetErrorLevel(elMedium)
  .SetRenderOptions(LOptions)
  .GenerateBitmap;

// Exibir em um TImage
Image1.Picture.Assign(LBmp);
LBmp.Free;
