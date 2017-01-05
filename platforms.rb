PLATFORMS = {
  "debian" => {
    "7" => {
      "codename" => "wheezy",
      "architectures" => ["i386", "x86_64"]
    },
    "8" => {
      "codename" => "jessie",
      "architectures" => ["i386", "x86_64"]
    }
  },
  "el" => {
    "5" => {
      "architectures" => ["i386", "x86_64"]
    },
    "6" => {
      "architectures" => ["i386", "x86_64"]
    },
    "7" => {
      "architectures" => ["i386", "x86_64"]
    }
  },
  "freebsd" => {
    "9" => {
      "architectures" => ["i386", "amd64"]
    },
    "10" => {
      "architectures" => ["i386", "amd64"]
    },
    "11" => {
      "architectures" => ["amd64"]
    }
  },
  "ubuntu" => {
    "12.04" => {
      "codename" => "precise",
      "architectures" => ["i386", "amd64"]
    },
    "14.04" => {
      "codename" => "trusty",
      "architectures" => ["i386", "amd64"]
    },
    "16.04" => {
      "codename" => "xenial",
      "architectures" => ["i386", "amd64"]
    }
  }
}
