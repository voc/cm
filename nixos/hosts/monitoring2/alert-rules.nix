[
  {
    name = "certificates";
    rules = [
      {
        alert = "CertificateExpiring";
        expr = "telegraf_x509_cert_expiry < 20*24*3600";
        annotations = {
          summary = "Certificate for {{ $labels.common_name }} on {{ $labels.host }} expires in {{ $value | humanizeDuration }}";
        };
      }
    ];
  }
]
