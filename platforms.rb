PLATFORMS = {
  "aix" => {
    "base_path" => "/srv/aix",
    "versions" => {
      "6.1" => {
        "architectures" => ["powerpc"]
      }
    }
  },
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
      },
      "9" => {
        "codename" => "stretch",
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
        "architectures" => ["amd64"]
      },
      "11" => {
        "architectures" => ["amd64"]
      }
    }
  },
  "mac_os_x" => {
    "base_path" => "/srv/osx",
    "versions" => {
      "10.10" => {
        "architectures" => ["x86_64"]
      },
      "10.11" => {
        "architectures" => ["x86_64"]
      },
      "10.12" => {
        "architectures" => ["x86_64"]
      }
    }
  },
  "solaris2" => {
    "base_path" => "/srv/solaris",
    "versions" => {
      "5.10" => {
        "architectures" => ["i386"]
      },
      "5.11" => {
        "architectures" => ["i386"]
      }
    }
  },
  "ubuntu" => {
    "base_path" => "/srv/freight",
    "versions" => {
      "12.04" => {
        "codename" => ["precise"],
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
  },
  "windows" => {
    "base_path" => "/srv/msi",
    "versions" => {
      "2012r2" => {
        "architectures" => ["i386", "x86_64"]
      },
      "2008r2" => {
        "architectures" => ["i386", "x86_64"]
      }
    }
  }
}

ENTERPRISE_PLATFORMS = {
  "debian" => {
    "base_path" => "/srv/freight",
    "versions" => {
      "6" => {
        "codename" => "sensu-enterprise",
        "architectures" => ["all"]
      }
    }
  },
  "el" => {
    "base_path" => "/srv/createrepo",
    "versions" => {
      "5" => {
        "architectures" => ["noarch"]
      }
    }
  }
}

ENTERPRISE_DASHBOARD_PLATFORMS = {
  "debian" => {
    "base_path" => "/srv/freight",
    "versions" => {
      "6" => {
        "codename" => "sensu-enterprise",
        "architectures" => ["i386", "x86_64"]
      }
    }
  },
  "el" => {
    "base_path" => "/srv/createrepo",
    "versions" => {
      "5" => {
        "architectures" => ["i386", "x86_64"]
      }
    }
  }
}
