{ }:
[
  # alert rule groups
  {
    name = "network";
    rules = [
      {
        alert = "CertificateExpiring";
        expr = "telegraf_x509_cert_expiry < 20*24*3600";
        annotations = {
          summary = "Certificate for {{ $labels.common_name }} on {{ $labels.host }} expires in {{ $value | humanizeDuration }}";
        };
      }
      {
        alert = "Pingv4Down";
        expr = ''probe_success{job="blackbox-ipv4"} == 0'';
        annotations = {
          summary = "Host {{ $labels.instance }} is unreachable via ICMPv4";
        };
      }
      {
        alert = "Pingv6Down";
        expr = ''probe_success{job="blackbox-ipv6"} == 0'';
        annotations = {
          summary = "Host {{ $labels.instance }} is unreachable via ICMPv6";
        };
      }
    ];
  }
  {
    name = "transcoding";
    rules = [
      {
        alert = "TranscodeStalling";
        expr = "telegraf_transcoding_speed_factor_gauge < 0.95";
        annotations = {
          summary = "Stream {{ $labels.stream_id }} transcoding is stalling on {{ $labels.host }}";
        };
      }
      # {
      #   alert = "TranscodeInvalidSegmentDurations";
      #   expr = "max by(slug)(telegraf_playlist_duration_diff_max_seconds_gauge) > 0.5";
      #   annotations = {
      #     summary = "Stream {{ $labels.slug }} transcode is producing invalid HLS segment durations";
      #   };
      # }
    ];
  }
  {
    name="ingest";
    rules = [
      {
        alert = "SrtIngestPacketLoss";
        expr = ''max by(stream_id)(label_replace((rate(telegraf_srtrelay_srt_receive_dropped_packets_total_counter{stream_id=~"publish/.*"})+ rate(telegraf_srtrelay_srt_receive_lost_packets_total_counter)) / rate(telegraf_srtrelay_srt_receive_packets_total_counter)*100, "stream_id", "$1", "stream_id", "publish/([^/]+).*")) > 5'';
        annotations = {
          summary = "Stream {{ $labels.stream_id }} SRT ingest has high packet loss";
        };
      }
    ];
  }
  {
    name="streaming";
  }
]
