PLATFORMS = {
  "debian" => {
    "base_path" => "/srv/freight",
    "versions" => {
      "7" => {
        "codename" => "wheezy",
        "architectures" => ["i386", "x86_64"],
      },
      "8" => {
        "codename" => "jessie",
        "architectures" => ["x86_64"]
      }
    }
  },
  "el" => {
    "base_path" => "/srv/createrepo",
    "versions" => {
      "5" => {
        "architectures" => ["i386", "x86_64"]
      },
      "6" => {
        "architectures" => ["i386", "x86_64"]
      },
      "7" => {
        "architectures" => ["x86_64"]
      }
    }
  },
  "freebsd" => {
    "base_path" => "/srv/freebsd",
    "versions" => {
      "10" => {
        "architectures" => ["i386", "amd64"]
      },
      "11" => {
        "architectures" => ["amd64"]
      }
    }
  },
  "ubuntu" => {
    "base_path" => "/srv/freight",
    "versions" => {
      "12.04" => {
        "codename" => "precise",
        "architectures" => ["i386", "x86_64"]
      },
      "14.04" => {
        "codename" => "trusty",
        "architectures" => ["i386", "x86_64"]
      },
      "16.04" => {
        "codename" => "xenial",
        "architectures" => ["x86_64"]
      }
    }
  }
}
