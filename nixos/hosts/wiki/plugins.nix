{ pkgs, ... }:

let
  mkPlugin = base: pkgs.stdenv.mkDerivation ( base // {
    installPhase = ''
      mkdir -p $out
      cp --recursive * $out
    '';
  });
in
{
  config.services.dokuwiki.sites."wiki.lan.c3voc.de".pluginsConfig = {};
  config.services.dokuwiki.sites."wiki.lan.c3voc.de".plugins = [
    (mkPlugin rec {
      name = "404manager";
      version = "1.2.0";
      src = pkgs.fetchFromGitHub {
        owner = "gerardnico";
        repo = "dokuwiki-plugin-404manager";
        rev = "v${version}";
        hash = "sha256-f86T8wmMDsnSEp8JEVT/FttUsG20rzsc3psn0QoBo7c=";
      };
    })
    (mkPlugin rec {
      name = "addnewpage";
      version = "2023-05-10";
      src = pkgs.fetchFromGitHub {
        owner = "dregad";
        repo = "dokuwiki-plugin-addnewpage";
        rev = version;
        hash = "sha256-+XP0rb5AJFlnKZRrdsOxu7OUBk11v8vL0iuE6l1hvdY=";
      };
    })
    (mkPlugin rec {
      name = "batchedit";
      version = "2024-02-12";
      src = pkgs.fetchFromGitHub {
        owner = "dwp-forge";
        repo = name;
        rev = "v.${version}";
        hash = "sha256-t4NtCrsjiVSbevli69k0/a/VBvuMifjg+OXI6QY4Brg=";
      };
    })
    (mkPlugin rec {
      name = "bootnote";
      version = "2017-08-08";
      src = pkgs.fetchFromGitHub {
        owner = "algorys";
        repo = name;
        rev = "3c4730e5283e93a9c4efee491bffeab3c495a493";
        hash = "sha256-NYFvPsT+XnGY5pZ3QwGni7x8a63gIaJdWwqlD1MSedk=";
      };
    })
    (mkPlugin rec {
      name = "bootswrapper";
      version = "2020-09-03";
      src = pkgs.fetchFromGitHub {
        owner = "giterlizzi";
        repo = "dokuwiki-plugin-bootswrapper";
        rev = "v${version}";
        hash = "sha256-IOCxPUTegVQoBese7kDcf8zsg2yCBFpc0/V/HcLK+TM=";
      };
    })
    (mkPlugin rec {
      name = "bureaucracy";
      version = "2023-05-16";
      src = pkgs.fetchFromGitHub {
        owner = "splitbrain";
        repo = "dokuwiki-plugin-bureaucracy";
        rev = version;
        hash = "sha256-jOFc6sMhzp52eGE68u+Irfy+NRN+CA1s2w6eMKDM5B0=";
      };
    })
    (mkPlugin rec {
      name = "captcha";
      version = "2023-12-06";
      src = pkgs.fetchFromGitHub {
        owner = "splitbrain";
        repo = "dokuwiki-plugin-captcha";
        rev = version;
        hash = "sha256-Do6jAzFBCXPNwDS03QM5xB/5UjfJvuDNWLDafMvKFQw=";
      };
    })
    (mkPlugin rec {
      name = "catlist";
      version = "2023-12-29";
      src = pkgs.fetchFromGitHub {
        owner = "xif-fr";
        repo = "dokuwiki-plugin-catlist";
        rev = "9eab2c7012cea138e6691a81c2fd1258ebb1fe53";
        hash = "sha256-n8T0qT/BfS5BQAga+9SSOgeKKHYvQ2r7QpqxrEMelho=";
      };
    })
    (mkPlugin rec {
      name = "cellbg";
      version = "1.0.1";
      src = pkgs.fetchFromGitHub {
        owner = "dr4Ke";
        repo = "cellbg";
        rev = version;
        hash = "sha256-LK6fFLr4jZLRBJGifTeXTk++9hfV3ZqM4f7HnJSDTFc=";
      };
    })
    (mkPlugin rec {
      name = "clearfloat";
      version = "2020-08-04";
      src = pkgs.fetchFromGitHub {
        owner = "i-net-software";
        repo = "dokuwiki-plugin-clearfloat";
        rev = version;
        hash = "sha256-mEFO50Kj4wVuvaGFJ+4WTcq3Qo011ZUBnW6wcGISCuk=";
      };
    })
    (mkPlugin rec {
      name = "commentsyntax";
      version = "2023-04-13";
      src = pkgs.fetchFromGitHub {
        owner = "ssahara";
        repo = "dw-plugin-commentsyntax";
        rev = "df4d37db112f092e48ee3b631a83c16bb7153c09";
        hash = "sha256-nWfAgfIKC/P6aQt4NWVyaOgRPfy0Rt7qX6qeJiSHh7c=";
      };
    })
    (mkPlugin rec {
      name = "creole";
      version = "2020-10-11";
      src = pkgs.fetchFromGitHub {
        owner = "dokufreaks";
        repo = "plugin-creole";
        rev = version;
        hash = "sha256-pWWosHB8ViK+GDnyj6k8+Sa5Saf7bDW0bd5nPkv/Utg=";
      };
    })
    (mkPlugin rec {
      name = "data";
      version = "2024-01-30";
      src = pkgs.fetchFromGitHub {
        owner = "splitbrain";
        repo = "dokuwiki-plugin-data";
        rev = version;
        hash = "sha256-b9CcqlkdV0B+ow6ge2MtqDpP+ySl2tTFB55bA2Uexzw=";
      };
    })
    (mkPlugin rec {
      name = "doodle4";
      version = "2019-04-02";
      src = pkgs.fetchFromGitHub {
        owner = "nstueber";
        repo = "dokuwiki-plugin-doodle4";
        rev = "cebf5c71c291d15189d7ad0cd1121624fedd8fa0";
        hash = "sha256-pxF6deK/5FABVvz4GCz3iYgW6owf1rSOiCZDbJ55n98=";
      };
    })
    (mkPlugin rec {
      name = "drawio";
      version = "0.2.6";
      src = pkgs.fetchFromGitHub {
        owner = "lejmr";
        repo = "dokuwiki-plugin-drawio";
        rev = version;
        hash = "sha256-6hVBY/k35rv55qwuh+SLP12Xbkz/ibCDi88mubB9lT4=";
      };
    })
    (mkPlugin rec {
      name = "dropfiles";
      version = "2020-03-18";
      src = pkgs.fetchFromGitHub {
        owner = "cosmocode";
        repo = "dokuwiki-plugin-dropfiles";
        rev = version;
        hash = "sha256-0fHphOdw9qZHfSYNhCN891C5VIyvaiCP0EWm73IxJ5A=";
      };
    })
    (mkPlugin rec {
      name = "edittable";
      version = "2023-01-14";
      src = pkgs.fetchFromGitHub {
        owner = "cosmocode";
        repo = name;
        rev = version;
        hash = "sha256-Mns8zgucpJrg1xdEopAhd4q1KH7j83Mz3wxuu4Thgsg=";
      };
    })
    (mkPlugin rec {
      name = "filelisting";
      version = "2023-09-27";
      src = pkgs.fetchFromGitHub {
        owner = "cosmocode";
        repo = "dokuwiki-plugin-filelisting";
        rev = version;
        hash = "sha256-daFd/BinRZBP5Lrl5P+JgKtm0EFrY2UNFM0bAw0MHm0=";
      };
    })
    (mkPlugin rec {
      name = "fontawsome";
      version = "2013-12-08";
      src = pkgs.fetchFromGitHub {
        owner = "mmedvede";
        repo = "dokuwiki-plugin-fontawesome";
        rev = version;
        hash = "sha256-z4ereAcQ41VRtD8SDyvua4mhZAPkOO8Nfhjo92+iUSc=";
      };
    })
    (mkPlugin rec {
      name = "gallery";
      version = "2023-12-08";
      src = pkgs.fetchFromGitHub {
        owner = "splitbrain";
        repo = "dokuwiki-plugin-gallery";
        rev = version;
        hash = "sha256-dpjC5AwqCN4cLxdG4wip65w3Y6sK3/kWL3PNKjbgS1A=";
      };
    })
    (mkPlugin rec {
      name = "hidden";
      version = "2023-11-07";
      src = pkgs.fetchFromGitHub {
        owner = "gturri";
        repo = name;
        rev = "2f7c9a275e9da22276610cdb8c8f58759a15c69d";
        hash = "sha256-9GnTM0/3R2HY3AUhHtQfvYdvlK0BjPoMl0R4XxCneic=";
      };
    })
    (mkPlugin rec {
      name = "htmlok";
      version = "2023-05-10";
      src = pkgs.fetchFromGitHub {
        owner = "saggi-dw";
        repo = "dokuwiki-plugin-htmlok";
        rev = version;
        hash = "sha256-3s+WAb1BG2mq8+wxpQ6HgPJZ+dx6v5e+vMXaOiLYceo=";
      };
    })
    (mkPlugin rec {
      name = "iframe";
      version = "2023-08-18";
      src = pkgs.fetchFromGitHub {
        owner = "Chris--S";
        repo = "dokuwiki-plugin-iframe";
        rev = "6fd029ccf3c39975dba243424eccd690add5f07d";
        hash = "sha256-OcP4lUgjydjgkEhif5XsVfssWy76sLUoYmcq1FhBDq8=";
      };
    })
    (mkPlugin rec {
      name = "imgpaste";
      version = "2023-02-08";
      src = pkgs.fetchFromGitHub {
        owner = "cosmocode";
        repo = "dokuwiki-plugin-imgpaste";
        rev = version;
        hash = "sha256-aAxuS2nQPXmMMB//ksyuTgSq/ar/BJQFPuzhD2B5iz0=";
      };
    })
    (mkPlugin rec {
      name = "include";
      version = "2023-09-22";
      src = pkgs.fetchFromGitHub {
        owner = "dokufreaks";
        repo = "plugin-include";
        rev = "86d24a163e94f506f1192c3ab5a4e111a1f1e9d8";
        hash = "sha256-PEN0wuLKu6eGYYJ9jB7Kkwn9K2QGXlQw09CfxQ2SSxA=";
      };
    })
    (mkPlugin rec {
      name = "interwikipaste";
      version = "2021-05-25";
      src = pkgs.fetchFromGitHub {
        owner = "cosmocode";
        repo = "dokuwiki-plugin-interwikipaste";
        rev = version;
        hash = "sha256-sA3yIUpKeudDP0DdX9tkVy+6ajj/54UVSF7FJVKdMPU=";
      };
    })
    (mkPlugin rec {
      name = "leaflet";
      version = "1.6.0-1";
      src = pkgs.fetchFromGitLab {
        owner = "asereq";
        repo = "dokuwiki-plugin-leaflet";
        rev = version;
        hash = "sha256-yotSSQMFnVSAr30QlNSLqnIVJUiUjW3Wp7I+LMNug3w=";
      };
    })
    (mkPlugin rec {
      name = "markdowku";
      version = "2021-12-04";
      src = pkgs.fetchFromGitHub {
        owner = "Medieninformatik-Regensburg";
        repo = "dokuwiki-plugin-markdowku";
        rev = "a871977d62bdec71df0acca66a7c7c307e550f6f";
        hash = "sha256-uzREhVl4iuXa5s9vXkGHmlBa/vcVxF6XSEePGnS8j7U=";
      };
    })
    (mkPlugin rec {
      name = "move";
      version = "2023-08-15";
      src = pkgs.fetchFromGitHub {
        owner = "michitux";
        repo = "dokuwiki-plugin-move";
        rev = "f1684ff5153a8c41b0da552bdbff1e1bcc6a1ed3";
        hash = "sha256-1qf461XwKbLIArtjO4ge3ST8IYmJYA3FIyHL/OZ0R/M=";
      };
    })
    (mkPlugin rec {
      name = "multiorphan";
      version = "2021-12-20";
      src = pkgs.fetchFromGitHub {
        owner = "i-net-software";
        repo = "dokuwiki-plugin-multiorphan";
        rev = version;
        hash = "sha256-ZBPIRQh4ET8R+G0JyKXevfMpaCodLSsvL9zjzqf2C2c=";
      };
    })
    (mkPlugin rec {
      name = "newpagetemplate";
      version = "2023-10-19";
      src = pkgs.fetchFromGitHub {
        owner = "turnermm";
        repo = name;
        rev = "release_${version}";
        hash = "sha256-ahQeaXF9Lh/jm4HXD1c24WouSS8ryrDpXoVZwxW9Qik=";
      };
    })
    (mkPlugin rec {
      name = "oauth";
      version = "2024-03-05";
      src = pkgs.fetchFromGitHub {
        owner = "cosmocode";
        repo = "dokuwiki-plugin-oauth";
        rev = version;
        hash = "sha256-eWXwdR+fH+1Ir2/c8TWkUzKMbtbWVtBS+j+5OP3bNjk=";
      };
    })
    (mkPlugin rec {
      name = "oauthgeneric";
      version = "2024-03-21";
      src = pkgs.fetchFromGitHub {
        owner = "cosmocode";
        repo = "dokuwiki-plugin-oauthgeneric";
        rev = version;
        hash = "sha256-lcD7u6Rr+FXo6rAT8uY1fnbDlSVPHTtDacPdsZBoHGg=";
      };
    })
    (mkPlugin rec {
      name = "odt";
      version = "2023-03-03";
      src = pkgs.fetchFromGitHub {
        owner = "lpaulsen93";
        repo = "dokuwiki-plugin-odt";
        rev = version;
        hash = "sha256-xkV+CT2n78a28/MkbUveJi+bETt6j3oVxxzcq+2kCEM=";
      };
    })
    (mkPlugin rec {
      name = "orphanswanted";
      version = "2023-05-30";
      src = pkgs.fetchFromGitHub {
        owner = "lupo49";
        repo = "dokuwiki-plugin-orphanswanted";
        rev = version;
        hash = "sha256-ocNl+AJE6tOxE0HKDSeC5NVC+Dgg5av4b5awWAv00Kc=";
      };
    })
    (mkPlugin rec {
      name = "pagebreak";
      version = "2016-02-16";
      src = pkgs.fetchFromGitHub {
        owner = "micgro42";
        repo = "dokuwiki-plugin-pagebreak";
        rev = "6a9511e5c7411f0e3b4792711986e722c08eb6d5";
        hash = "sha256-AjCWyW6FdZugL+obKU6g0LvcxfCDPaqlnwF8ROub1jQ=";
      };
    })
    (mkPlugin rec {
      name = "pagemod";
      version = "1.2";
      src = pkgs.fetchFromGitHub {
        owner = "BaselineIT";
        repo = "dokuwiki-pagemod";
        rev = "release-${version}";
        hash = "sha256-Vto9fhv96NhKMXDp45DSrrgsdWbjIn6F1nEoTPcPOZk=";
      };
    })
    (mkPlugin rec {
      name = "pageredirect";
      version = "2024-03-01";
      src = pkgs.fetchFromGitHub {
        owner = "glensc";
        repo = "dokuwiki-plugin-pageredirect";
        rev = version;
        hash = "sha256-G4ORUriMFkFU0dz8QfDexMzaHDE/oNSx2QzB8Gc5zis=";
      };
    })
    (mkPlugin rec {
      name = "passpolicy";
      version = "2022-01-11";
      src = pkgs.fetchFromGitHub {
        owner = "splitbrain";
        repo = "dokuwiki-plugin-passpolicy";
        rev = version;
        hash = "sha256-8nq88cPQ6bysepIruDllvsGudQ2m6kjwmygrXT+yuuw=";
      };
    })
    (mkPlugin rec {
      name = "removeold";
      version = "2016-07-07";
      src = pkgs.fetchFromGitHub {
        owner = "Taggic";
        repo = name;
        rev = "2660bdd9e0b0b078009ef452822ad663c76eecc9";
        hash = "sha256-MrdzKjchF/1gz0yMp1VWozYqYBF4k3TUhUekisuQqMI=";
      };
    })
    (mkPlugin rec {
      name = "semantic";
      version = "2023-02-02";
      src = pkgs.fetchFromGitHub {
        owner = "giterlizzi";
        repo = "dokuwiki-plugin-semantic";
        rev = "198c0ba4904aa3aedced2b1ba15c1d159dec485f";
        hash = "sha256-IuCZ2rmUGtGG/kmKCxlNjYxKPdLP+bheGb8fYu+W1ko=";
      };
    })
    (mkPlugin rec {
      name = "socialcards";
      version = "2023-06-30";
      src = pkgs.fetchFromGitHub {
        owner = "mprins";
        repo = "dokuwiki-plugin-socialcards";
        rev = version;
        hash = "sha256-Bi9i+Gcy8V6mDcyeFQfZyDsMctZ8udbOkRGuUH5FAg4=";
      };
    })
    (mkPlugin rec {
      name = "sqlite";
      version = "2024-03-05";
      src = pkgs.fetchFromGitHub {
        owner = "cosmocode";
        repo = name;
        rev = version;
        hash = "sha256-S9bbs8nGpstcF98SqSW2y2m/BWUi6ZfHD+uIIA32JXo=";
      };
    })
    (mkPlugin rec {
      name = "struct";
      version = "2024-02-16";
      src = pkgs.fetchFromGitHub {
        owner = "cosmocode";
        repo = "dokuwiki-plugin-struct";
        rev = version;
        hash = "sha256-ZicRQjXYao+y1IIw/x9iA036s+wgjmHN+CmRMibJIlg=";
      };
    })
    (mkPlugin rec {
      name = "structgeohash";
      version = "1.0";
      src = pkgs.fetchFromGitLab {
        owner = "asereq";
        repo = "dokuwiki-plugin-structgeohash";
        rev = version;
        hash = "sha256-pB9i82lS52KE+ReNhsVQL3LYQwEjo2M81t3X19KshOo=";
      };
    })
    (mkPlugin rec {
      name = "tablecalc";
      version = "2020-08-27";
      src = pkgs.fetchzip {
        url = "https://narezka.org/cfd/msgdb/740/tablecalc.zip";
        hash = "sha256-u+ZDmWvbgh9XRkKOD2/GmqeWn8+n/qX+5Sc6BCuApPM=";
      };
    })
    (mkPlugin rec {
      name = "tablelayout";
      version = "2022-03-28";
      src = pkgs.fetchFromGitHub {
        owner = "cosmocode";
        repo = "dokuwiki-plugin-tablelayout";
        rev = version;
        hash = "sha256-5qsauw28MuiWngy+lEeqYporzoT4VmO+9BTL/Pd5uYg=";
      };
    })
    (mkPlugin rec {
      name = "toctweak";
      version = "2018-01-08";
      src = pkgs.fetchFromGitHub {
        owner = "ssahara";
        repo = "dw-plugin-toctweak";
        rev = version;
        hash = "sha256-ljZBPgMMjjkPk5h1GfXp0IqSW2bzGLALKEvvzUuOAMg=";
      };
    })
    (mkPlugin rec {
      name = "todo";
      version = "2024-03-04";
      src = pkgs.fetchFromGitHub {
        owner = "leibler";
        repo = "dokuwiki-plugin-todo";
        rev = version;
        hash = "sha256-j2RYVC7IuZQB82d6AkcEGZAiCf4zTeDJB1xWiuO3H74=";
      };
    })
    (mkPlugin rec {
      name = "translation";
      version = "2023-12-14";
      src = pkgs.fetchFromGitHub {
        owner = "splitbrain";
        repo = "dokuwiki-plugin-translation";
        rev = version;
        hash = "sha256-nzF1Khjl327LegHYVliLdr+nWDOvvi4T6RDnsIaZ3jg=";
      };
    })
    (mkPlugin rec {
      name = "userpagecreate";
      version = "2021-07-15";
      src = pkgs.fetchFromGitHub {
        owner = "cosmocode";
        repo = name;
        rev = version;
        hash = "sha256-iZGykKY7BXm63vbQmVOtfq6ZGAVhlA9hqe/EZJ0oqjg=";
      };
    })
    (mkPlugin rec {
      name = "wrap";
      version = "2023-08-13";
      src = pkgs.fetchFromGitHub {
        owner = "selfthinker";
        repo = "dokuwiki_plugin_wrap";
        rev = "v${version}";
        hash = "sha256-my7XW/Blyj6PLZJqs3MX3kRWXpInB913gYZnQ70v9Rs=";
      };
    })
  ];
}
