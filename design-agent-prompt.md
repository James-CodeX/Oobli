# Design Export Context

- Generated at: `2026-11-21T05:55:09.868Z`
- Document ID: `343a53b2-4f51-4571-bf58-f40d82898d4b`
- Page count: 10

## Original Prompt

```text
i want an app that looks and feels and interacts like brilliant or duolingo and very minimalist in the design. it has a financial spending and planning app with AI. because i am in Kenya, i can just give access to my messages and it can pull all of them and using AI just well present the spending from mpesa (eg. pochi la biashara, tills and paybill which are all under single sender Mpesa) and banks tarnsaction messages. and you can change what allocation was by editing if need be, for example it might categorise a spending as sent to someone yet it was a grocery i did and just sent to someone, it should also allow one to add. 

all tis should be very well presented in charts and graphs. irt should have a planning page where you  can add how much money you are anticipating to get and write a plan using AI. 

it should have several onboarding screens very well designed

brand directions
- Oobli — App name
- Meet Oobli — Onboarding introduction
- Oobli says... — AI insights
- Oobli Plans — Financial planning
- Oobli Goals — Savings goals
- Oobli Wrapped — Monthly spending recap
```

## Theme (JSON)

```json
{
  "schema_version": 2,
  "fonts": {
    "primary": "google:Outfit",
    "secondary": "google:Nunito",
    "mono": "google:Space Grotesk"
  },
  "colors": {
    "light": {
      "primary": "#58CC02",
      "on_primary": "#FFFFFF",
      "primary_container": "#58CC021A",
      "on_primary_container": "#4B4B4B",
      "secondary": "#1CB0F6",
      "on_secondary": "#FFFFFF",
      "secondary_container": "#1CB0F61A",
      "on_secondary_container": "#4B4B4B",
      "accent": "#FFC800",
      "on_accent": "#000000",
      "accent_container": "#FFC8001A",
      "on_accent_container": "#4B4B4B",
      "background": "#FFFFFF",
      "on_background": "#4B4B4B",
      "secondary_background": "#F7F7F7",
      "surface": "#FFFFFF",
      "on_surface": "#4B4B4B",
      "surface_variant": "#E5E5E5",
      "on_surface_variant": "#777777",
      "primary_text": "#4B4B4B",
      "secondary_text": "#777777",
      "hint": "#AFAFAF",
      "outline": "#E5E5E5",
      "divider": "#E5E5E5",
      "success": "#58CC02",
      "on_success": "#FFFFFF",
      "warning": "#FF9600",
      "on_warning": "#FFFFFF",
      "error": "#EA2B2B",
      "on_error": "#FFFFFF",
      "info": "#1CB0F6",
      "on_info": "#FFFFFF",
      "transparent": "#00000000",
      "full_contrast": "#000000"
    },
    "dark": {
      "primary": "#78D937",
      "on_primary": "#000000",
      "primary_container": "#78D93724",
      "on_primary_container": "#FFFFFF",
      "secondary": "#49C0F8",
      "on_secondary": "#FFFFFF",
      "secondary_container": "#49C0F824",
      "on_secondary_container": "#FFFFFF",
      "accent": "#FFD933",
      "on_accent": "#000000",
      "accent_container": "#FFD93324",
      "on_accent_container": "#FFFFFF",
      "background": "#131F24",
      "on_background": "#FFFFFF",
      "secondary_background": "#202F36",
      "surface": "#202F36",
      "on_surface": "#FFFFFF",
      "surface_variant": "#37464F",
      "on_surface_variant": "#AFAFAF",
      "primary_text": "#FFFFFF",
      "secondary_text": "#AFAFAF",
      "hint": "#777777",
      "outline": "#37464F",
      "divider": "#37464F",
      "success": "#78D937",
      "on_success": "#000000",
      "warning": "#FFB340",
      "on_warning": "#000000",
      "error": "#FF4B4B",
      "on_error": "#FFFFFF",
      "info": "#49C0F8",
      "on_info": "#FFFFFF",
      "transparent": "#00000000",
      "full_contrast": "#FFFFFF"
    }
  },
  "text_styles": {
    "display_large": {
      "font": "primary",
      "size": 58,
      "weight": 800,
      "height": 1.1
    },
    "display_medium": {
      "font": "primary",
      "size": 46,
      "weight": 800,
      "height": 1.15
    },
    "display_small": {
      "font": "primary",
      "size": 38,
      "weight": 800,
      "height": 1.2
    },
    "headline_large": {
      "font": "primary",
      "size": 32,
      "weight": 700,
      "height": 1.2
    },
    "headline_medium": {
      "font": "primary",
      "size": 26,
      "weight": 700,
      "height": 1.25
    },
    "headline_small": {
      "font": "primary",
      "size": 24,
      "weight": 700,
      "height": 1.3
    },
    "title_large": {
      "font": "secondary",
      "size": 20,
      "weight": 700,
      "height": 1.3
    },
    "title_medium": {
      "font": "secondary",
      "size": 17,
      "weight": 700,
      "height": 1.35
    },
    "title_small": {
      "font": "secondary",
      "size": 14,
      "weight": 700,
      "height": 1.4
    },
    "body_large": {
      "font": "secondary",
      "size": 17,
      "weight": 500,
      "height": 1.5
    },
    "body_medium": {
      "font": "secondary",
      "size": 15,
      "weight": 500,
      "height": 1.5
    },
    "body_small": {
      "font": "secondary",
      "size": 13,
      "weight": 500,
      "height": 1.5
    },
    "label_large": {
      "font": "mono",
      "size": 14,
      "weight": 600,
      "height": 1.3
    },
    "label_medium": {
      "font": "mono",
      "size": 12,
      "weight": 600,
      "height": 1.3
    },
    "label_small": {
      "font": "mono",
      "size": 10,
      "weight": 600,
      "height": 1.3
    }
  },
  "spacing": {
    "none": 0,
    "xs": 4,
    "sm": 8,
    "md": 16,
    "lg": 24,
    "xl": 32,
    "xxl": 48,
    "xxxl": 64
  },
  "radii": {
    "none": 0,
    "xs": 4,
    "sm": 8,
    "md": 12,
    "lg": 16,
    "xl": 20,
    "xxl": 28,
    "full": 9999
  },
  "shadows": {
    "none": {
      "color": "#00000000",
      "dx": 0,
      "dy": 0,
      "blur": 0,
      "spread": 0
    },
    "xs": {
      "color": "#0000000D",
      "dx": 0,
      "dy": 2,
      "blur": 0,
      "spread": 0
    },
    "sm": {
      "color": "#0000001A",
      "dx": 0,
      "dy": 2,
      "blur": 0,
      "spread": 0
    },
    "md": {
      "color": "#0000001A",
      "dx": 0,
      "dy": 4,
      "blur": 0,
      "spread": 0
    },
    "lg": {
      "color": "#0000001A",
      "dx": 0,
      "dy": 6,
      "blur": 0,
      "spread": 0
    },
    "xl": {
      "color": "#0000001A",
      "dx": 0,
      "dy": 8,
      "blur": 0,
      "spread": 0
    },
    "xxl": {
      "color": "#0000001A",
      "dx": 0,
      "dy": 12,
      "blur": 0,
      "spread": 0
    }
  },
  "gradients": {}
}
```

## Pages

### 1. Meet Oobli

- Frame ID: `frame2`
- Original page prompt: "A playful onboarding introduction screen with a character mascot"
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      },
      "safe_area": {
        "boolVal": {
          "value": true
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          },
          "padding": {
            "edgeInsets": {
              "top": 0,
              "right": 0,
              "bottom": 0,
              "left": 0,
              "token": "lg"
            }
          }
        },
        "children": [
          {
            "type": "row",
            "properties": {
              "align": {
                "align": {
                  "named": "center"
                }
              },
              "spacing": {
                "stringVal": {
                  "value": "xs"
                }
              }
            },
            "children": [
              {
                "type": "container",
                "properties": {
                  "width": {
                    "px": {
                      "value": 32,
                      "isInfinity": false
                    }
                  },
                  "height": {
                    "px": {
                      "value": 32,
                      "isInfinity": false
                    }
                  },
                  "bg": {
                    "color": {
                      "color": "primary"
                    }
                  },
                  "radius": {
                    "radius": {
                      "topLeft": 8,
                      "topRight": 8,
                      "bottomLeft": 8,
                      "bottomRight": 8
                    }
                  },
                  "align_child": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "icon",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "account_balance_wallet_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "on_surface"
                        }
                      },
                      "size": {
                        "numberVal": {
                          "value": 20
                        }
                      }
                    },
                    "editorId": "icon16"
                  }
                ],
                "editorId": "container28"
              },
              {
                "type": "text",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Oobli"
                    }
                  },
                  "style": {
                    "textStyle": {
                      "styleName": "title_large"
                    }
                  },
                  "font_weight": {
                    "numberVal": {
                      "value": 800
                    }
                  },
                  "color": {
                    "color": {
                      "color": "primary_text"
                    }
                  }
                },
                "editorId": "text36"
              }
            ],
            "editorId": "row22"
          },
          {
            "type": "spacer",
            "properties": {
              "flex": {
                "numberVal": {
                  "value": 1
                }
              }
            },
            "editorId": "spacer1"
          },
          {
            "type": "column",
            "properties": {
              "spacing": {
                "stringVal": {
                  "value": "xl"
                }
              },
              "align": {
                "align": {
                  "named": "center"
                }
              }
            },
            "children": [
              {
                "type": "container",
                "properties": {
                  "width": {
                    "px": {
                      "value": 240,
                      "isInfinity": false
                    }
                  },
                  "height": {
                    "px": {
                      "value": 240,
                      "isInfinity": false
                    }
                  },
                  "align_child": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "stack",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "container",
                        "properties": {
                          "width": {
                            "px": {
                              "value": 200,
                              "isInfinity": false
                            }
                          },
                          "height": {
                            "px": {
                              "value": 200,
                              "isInfinity": false
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 0,
                              "topRight": 0,
                              "bottomLeft": 0,
                              "bottomRight": 0,
                              "token": "full"
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "primary",
                              "opacityPercent": 10
                            }
                          },
                          "blur": {
                            "numberVal": {
                              "value": 40
                            }
                          }
                        },
                        "editorId": "container30"
                      },
                      {
                        "type": "container",
                        "properties": {
                          "width": {
                            "px": {
                              "value": 160,
                              "isInfinity": false
                            }
                          },
                          "height": {
                            "px": {
                              "value": 160,
                              "isInfinity": false
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 60,
                              "topRight": 60,
                              "bottomLeft": 60,
                              "bottomRight": 60
                            }
                          },
                          "gradient": {
                            "gradient": {
                              "type": "GRADIENT_TYPE_LINEAR",
                              "direction": "to_bottom_right",
                              "stops": [
                                {
                                  "color": "primary"
                                },
                                {
                                  "color": "accent"
                                }
                              ]
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "stack",
                            "properties": {
                              "align": {
                                "align": {
                                  "named": "center"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "row",
                                "properties": {
                                  "spacing": {
                                    "stringVal": {
                                      "value": "lg"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "container",
                                    "properties": {
                                      "width": {
                                        "px": {
                                          "value": 16,
                                          "isInfinity": false
                                        }
                                      },
                                      "height": {
                                        "px": {
                                          "value": 24,
                                          "isInfinity": false
                                        }
                                      },
                                      "radius": {
                                        "radius": {
                                          "topLeft": 0,
                                          "topRight": 0,
                                          "bottomLeft": 0,
                                          "bottomRight": 0,
                                          "token": "full"
                                        }
                                      },
                                      "bg": {
                                        "color": {
                                          "color": "on_primary"
                                        }
                                      }
                                    },
                                    "editorId": "container32"
                                  },
                                  {
                                    "type": "container",
                                    "properties": {
                                      "width": {
                                        "px": {
                                          "value": 16,
                                          "isInfinity": false
                                        }
                                      },
                                      "height": {
                                        "px": {
                                          "value": 24,
                                          "isInfinity": false
                                        }
                                      },
                                      "radius": {
                                        "radius": {
                                          "topLeft": 0,
                                          "topRight": 0,
                                          "bottomLeft": 0,
                                          "bottomRight": 0,
                                          "token": "full"
                                        }
                                      },
                                      "bg": {
                                        "color": {
                                          "color": "on_primary"
                                        }
                                      }
                                    },
                                    "editorId": "container33"
                                  }
                                ],
                                "editorId": "row23"
                              }
                            ],
                            "editorId": "stack2"
                          }
                        ],
                        "editorId": "container31"
                      }
                    ],
                    "editorId": "stack1"
                  }
                ],
                "editorId": "container29"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  },
                  "align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Meet Oobli"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "headline_large"
                        }
                      },
                      "font_weight": {
                        "numberVal": {
                          "value": 900
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      },
                      "text_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "editorId": "text37"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "max_width": {
                        "px": {
                          "value": 300,
                          "isInfinity": false
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Your AI financial companion that turns M-Pesa texts into clear spending plans."
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "body_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          },
                          "text_align": {
                            "align": {
                              "named": "center"
                            }
                          },
                          "line_height": {
                            "numberVal": {
                              "value": 1.5
                            }
                          }
                        },
                        "editorId": "text38"
                      }
                    ],
                    "editorId": "container34"
                  }
                ],
                "editorId": "column18"
              }
            ],
            "editorId": "column17"
          },
          {
            "type": "spacer",
            "properties": {
              "flex": {
                "numberVal": {
                  "value": 1
                }
              }
            },
            "editorId": "spacer2"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "radius": {
                "radius": {
                  "topLeft": 0,
                  "topRight": 0,
                  "bottomLeft": 0,
                  "bottomRight": 0,
                  "token": "xl"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "border": {
                "border": {
                  "width": 2,
                  "color": "outline"
                }
              },
              "shadow": {
                "stringVal": {
                  "value": "sm"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "width": {
                        "px": {
                          "value": 48,
                          "isInfinity": false
                        }
                      },
                      "height": {
                        "px": {
                          "value": 48,
                          "isInfinity": false
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "full"
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "success",
                          "opacityPercent": 15
                        }
                      },
                      "align_child": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "icon",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "auto_awesome_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_surface"
                            }
                          },
                          "size": {
                            "numberVal": {
                              "value": 24
                            }
                          }
                        },
                        "editorId": "icon17"
                      }
                    ],
                    "editorId": "container36"
                  },
                  {
                    "type": "expanded",
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "xs"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Oobli says..."
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_medium"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "on_surface"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text39"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "I've spotted 12 new M-Pesa transactions. Want me to categorize them?"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "body_medium"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary_text"
                                }
                              }
                            },
                            "editorId": "text40"
                          }
                        ],
                        "editorId": "column19"
                      }
                    ],
                    "editorId": "expanded8"
                  }
                ],
                "editorId": "row24"
              }
            ],
            "editorId": "container35"
          },
          {
            "type": "sizedbox",
            "properties": {
              "height": {
                "stringVal": {
                  "value": "xl"
                }
              }
            },
            "editorId": "sizedbox1"
          },
          {
            "type": "column",
            "properties": {
              "spacing": {
                "stringVal": {
                  "value": "lg"
                }
              },
              "cross_align": {
                "align": {
                  "named": "stretch"
                }
              }
            },
            "children": [
              {
                "type": "@progress_dots",
                "properties": {
                  "active_index": {
                    "numberVal": {
                      "value": 0
                    }
                  }
                },
                "editorId": "progressdots1"
              },
              {
                "type": "@std.button",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Get Started"
                    }
                  },
                  "size": {
                    "stringVal": {
                      "value": "large"
                    }
                  },
                  "full_width": {
                    "boolVal": {
                      "value": true
                    }
                  }
                },
                "editorId": "stdbutton2"
              },
              {
                "type": "@std.button",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "I already have an account"
                    }
                  },
                  "variant": {
                    "stringVal": {
                      "value": "ghost"
                    }
                  },
                  "size": {
                    "stringVal": {
                      "value": "medium"
                    }
                  },
                  "full_width": {
                    "boolVal": {
                      "value": true
                    }
                  }
                },
                "editorId": "stdbutton3"
              }
            ],
            "editorId": "column20"
          }
        ],
        "editorId": "column16"
      }
    ],
    "editorId": "scaffold1"
  }
}
```

### 2. SMS Sync Permissions

- Frame ID: `frame1`
- Original page prompt: "Onboarding screen to grant access to M-Pesa and bank transaction messages"
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "padding": {
            "edgeInsets": {
              "top": 0,
              "right": 0,
              "bottom": 0,
              "left": 0,
              "token": "lg"
            }
          },
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "row",
            "properties": {
              "spacing": {
                "stringVal": {
                  "value": "md"
                }
              },
              "cross_align": {
                "align": {
                  "named": "center"
                }
              }
            },
            "children": [
              {
                "type": "iconbutton",
                "properties": {
                  "name": {
                    "icon": {
                      "name": "close_rounded"
                    }
                  },
                  "color": {
                    "color": {
                      "color": "secondary_text"
                    }
                  },
                  "size": {
                    "numberVal": {
                      "value": 24
                    }
                  }
                },
                "editorId": "iconbutton1"
              },
              {
                "type": "expanded",
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "height": {
                        "px": {
                          "value": 12,
                          "isInfinity": false
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "divider"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "full"
                        }
                      },
                      "clip": {
                        "boolVal": {
                          "value": true
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "container",
                        "properties": {
                          "width": {
                            "px": {
                              "value": 280,
                              "isInfinity": false
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "success"
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 0,
                              "topRight": 0,
                              "bottomLeft": 0,
                              "bottomRight": 0,
                              "token": "full"
                            }
                          }
                        },
                        "editorId": "container38"
                      }
                    ],
                    "editorId": "container37"
                  }
                ],
                "editorId": "expanded9"
              }
            ],
            "editorId": "row25"
          },
          {
            "type": "spacer",
            "properties": {
              "flex": {
                "numberVal": {
                  "value": 1
                }
              }
            },
            "editorId": "spacer3"
          },
          {
            "type": "column",
            "properties": {
              "spacing": {
                "stringVal": {
                  "value": "lg"
                }
              },
              "cross_align": {
                "align": {
                  "named": "center"
                }
              }
            },
            "children": [
              {
                "type": "container",
                "properties": {
                  "height": {
                    "px": {
                      "value": 160,
                      "isInfinity": false
                    }
                  },
                  "width": {
                    "px": {
                      "value": 160,
                      "isInfinity": false
                    }
                  },
                  "align_child": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "lottie",
                    "properties": {
                      "source_desc": {
                        "imageSource": {
                          "type": "IMAGE_SOURCE_TYPE_URL",
                          "value": "https://dimg.dreamflow.cloud/v1/image/friendly+minimalist+owl-like+robot+mascot+waving"
                        }
                      },
                      "height": {
                        "px": {
                          "value": 140,
                          "isInfinity": false
                        }
                      }
                    },
                    "editorId": "lottie1"
                  }
                ],
                "editorId": "container39"
              },
              {
                "type": "container",
                "properties": {
                  "bg": {
                    "color": {
                      "color": "surface"
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "radius": {
                    "radius": {
                      "topLeft": 0,
                      "topRight": 0,
                      "bottomLeft": 0,
                      "bottomRight": 0,
                      "token": "lg"
                    }
                  },
                  "border": {
                    "border": {
                      "width": 2,
                      "color": "outline"
                    }
                  },
                  "shadow": {
                    "stringVal": {
                      "value": "sm"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Oobli says..."
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_medium"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_surface"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text41"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "I need to see your messages to magically organize your M-Pesa & Bank spending!"
                            }
                          },
                          "text_align": {
                            "align": {
                              "named": "center"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "body_large"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 600
                            }
                          }
                        },
                        "editorId": "text42"
                      }
                    ],
                    "editorId": "column23"
                  }
                ],
                "editorId": "container40"
              }
            ],
            "editorId": "column22"
          },
          {
            "type": "spacer",
            "properties": {
              "flex": {
                "numberVal": {
                  "value": 1
                }
              }
            },
            "editorId": "spacer4"
          },
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "radius": {
                "radius": {
                  "topLeft": 0,
                  "topRight": 0,
                  "bottomLeft": 0,
                  "bottomRight": 0,
                  "token": "xl"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "border": {
                "border": {
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  }
                },
                "children": [
                  {
                    "type": "@feature_row",
                    "properties": {
                      "icon": {
                        "stringVal": {
                          "value": "sms_rounded"
                        }
                      },
                      "title": {
                        "stringVal": {
                          "value": "SMS Access"
                        }
                      },
                      "description": {
                        "stringVal": {
                          "value": "To read M-Pesa, Pochi, and Bank transaction alerts automatically."
                        }
                      }
                    },
                    "editorId": "featurerow1"
                  },
                  {
                    "type": "@feature_row",
                    "properties": {
                      "icon": {
                        "stringVal": {
                          "value": "auto_awesome_rounded"
                        }
                      },
                      "title": {
                        "stringVal": {
                          "value": "AI Categorization"
                        }
                      },
                      "description": {
                        "stringVal": {
                          "value": "Oobli learns your habits to group groceries, rent, and fun."
                        }
                      }
                    },
                    "editorId": "featurerow2"
                  },
                  {
                    "type": "@feature_row",
                    "properties": {
                      "icon": {
                        "stringVal": {
                          "value": "security_rounded"
                        }
                      },
                      "title": {
                        "stringVal": {
                          "value": "Privacy First"
                        }
                      },
                      "description": {
                        "stringVal": {
                          "value": "Only financial messages are processed. Personal chats stay private."
                        }
                      }
                    },
                    "editorId": "featurerow3"
                  }
                ],
                "editorId": "column24"
              }
            ],
            "editorId": "container41"
          },
          {
            "type": "sizedbox",
            "properties": {
              "height": {
                "stringVal": {
                  "value": "lg"
                }
              }
            },
            "editorId": "sizedbox2"
          },
          {
            "type": "column",
            "properties": {
              "spacing": {
                "stringVal": {
                  "value": "md"
                }
              }
            },
            "children": [
              {
                "type": "@std.button",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Grant Access"
                    }
                  },
                  "size": {
                    "stringVal": {
                      "value": "large"
                    }
                  },
                  "full_width": {
                    "boolVal": {
                      "value": true
                    }
                  }
                },
                "editorId": "stdbutton4"
              },
              {
                "type": "@std.button",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "I'll add transactions manually"
                    }
                  },
                  "variant": {
                    "stringVal": {
                      "value": "ghost"
                    }
                  },
                  "size": {
                    "stringVal": {
                      "value": "medium"
                    }
                  },
                  "full_width": {
                    "boolVal": {
                      "value": true
                    }
                  }
                },
                "editorId": "stdbutton5"
              }
            ],
            "editorId": "column25"
          },
          {
            "type": "sizedbox",
            "properties": {
              "height": {
                "stringVal": {
                  "value": "md"
                }
              }
            },
            "editorId": "sizedbox3"
          },
          {
            "type": "text",
            "properties": {
              "content": {
                "stringVal": {
                  "value": "You can revoke this access anytime in your phone settings."
                }
              },
              "style": {
                "textStyle": {
                  "styleName": "label_small"
                }
              },
              "color": {
                "color": {
                  "color": "on_background"
                }
              },
              "text_align": {
                "align": {
                  "named": "center"
                }
              }
            },
            "editorId": "text43"
          }
        ],
        "editorId": "column21"
      }
    ],
    "editorId": "scaffold2"
  }
}
```

### 3. Gamified Setup

- Frame ID: `frame3`
- Original page prompt: "A series of minimalist steps to set up initial financial goals"
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "padding": {
            "edgeInsets": {
              "top": 0,
              "right": 0,
              "bottom": 0,
              "left": 0,
              "token": "lg"
            }
          },
          "spacing": {
            "stringVal": {
              "value": "xl"
            }
          },
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "column",
            "properties": {
              "spacing": {
                "stringVal": {
                  "value": "md"
                }
              },
              "cross_align": {
                "align": {
                  "named": "stretch"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "iconbutton",
                    "properties": {
                      "name": {
                        "icon": {
                          "name": "close_rounded"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      }
                    },
                    "editorId": "iconbutton2"
                  },
                  {
                    "type": "@progress_step",
                    "properties": {
                      "current": {
                        "numberVal": {
                          "value": 1
                        }
                      },
                      "total": {
                        "numberVal": {
                          "value": 3
                        }
                      }
                    },
                    "editorId": "progressstep1"
                  },
                  {
                    "type": "sizedbox",
                    "properties": {
                      "width": {
                        "px": {
                          "value": 40,
                          "isInfinity": false
                        }
                      }
                    },
                    "editorId": "sizedbox4"
                  }
                ],
                "editorId": "row26"
              },
              {
                "type": "row",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "width": {
                        "px": {
                          "value": 64,
                          "isInfinity": false
                        }
                      },
                      "height": {
                        "px": {
                          "value": 64,
                          "isInfinity": false
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "full"
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "accent",
                          "opacityPercent": 20
                        }
                      },
                      "align_child": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "lottie",
                        "properties": {
                          "source_desc": {
                            "imageSource": {
                              "type": "IMAGE_SOURCE_TYPE_URL",
                              "value": "https://dimg.dreamflow.cloud/v1/image/friendly+minimalist+mascot+waving"
                            }
                          },
                          "width": {
                            "px": {
                              "value": 50,
                              "isInfinity": false
                            }
                          },
                          "height": {
                            "px": {
                              "value": 50,
                              "isInfinity": false
                            }
                          }
                        },
                        "editorId": "lottie2"
                      }
                    ],
                    "editorId": "container42"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      },
                      "expanded": {
                        "expanded": {
                          "enabled": true,
                          "flex": 1
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Oobli says..."
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_background"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text44"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Let's set your focus for this month. What's the big plan?"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 800
                            }
                          }
                        },
                        "editorId": "text45"
                      }
                    ],
                    "editorId": "column28"
                  }
                ],
                "editorId": "row27"
              }
            ],
            "editorId": "column27"
          },
          {
            "type": "column",
            "properties": {
              "spacing": {
                "stringVal": {
                  "value": "md"
                }
              },
              "scroll": {
                "boolVal": {
                  "value": true
                }
              }
            },
            "children": [
              {
                "type": "@goal_option",
                "properties": {
                  "title": {
                    "stringVal": {
                      "value": "Kill the Debt"
                    }
                  },
                  "subtitle": {
                    "stringVal": {
                      "value": "Clear those M-Shwari & Fuliza balances"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "local_fire_department_rounded"
                    }
                  },
                  "selected": {
                    "boolVal": {
                      "value": true
                    }
                  }
                },
                "editorId": "goaloption1"
              },
              {
                "type": "@goal_option",
                "properties": {
                  "title": {
                    "stringVal": {
                      "value": "Smart Saving"
                    }
                  },
                  "subtitle": {
                    "stringVal": {
                      "value": "Build a buffer for the rainy days"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "savings_rounded"
                    }
                  }
                },
                "editorId": "goaloption2"
              },
              {
                "type": "@goal_option",
                "properties": {
                  "title": {
                    "stringVal": {
                      "value": "Investment Mode"
                    }
                  },
                  "subtitle": {
                    "stringVal": {
                      "value": "Grow wealth in M-Mali or Stocks"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "trending_up_rounded"
                    }
                  }
                },
                "editorId": "goaloption3"
              },
              {
                "type": "@goal_option",
                "properties": {
                  "title": {
                    "stringVal": {
                      "value": "Just Tracking"
                    }
                  },
                  "subtitle": {
                    "stringVal": {
                      "value": "I want to see where my M-Pesa goes"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "visibility_rounded"
                    }
                  }
                },
                "editorId": "goaloption4"
              }
            ],
            "editorId": "column29"
          },
          {
            "type": "spacer",
            "properties": {
              "flex": {
                "numberVal": {
                  "value": 1
                }
              }
            },
            "editorId": "spacer5"
          },
          {
            "type": "column",
            "properties": {
              "spacing": {
                "stringVal": {
                  "value": "md"
                }
              },
              "cross_align": {
                "align": {
                  "named": "stretch"
                }
              }
            },
            "children": [
              {
                "type": "container",
                "properties": {
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "radius": {
                    "radius": {
                      "topLeft": 0,
                      "topRight": 0,
                      "bottomLeft": 0,
                      "bottomRight": 0,
                      "token": "lg"
                    }
                  },
                  "bg": {
                    "color": {
                      "color": "surface_variant",
                      "opacityPercent": 30
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "sm"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "icon",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "auto_awesome_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_surface_variant"
                            }
                          },
                          "size": {
                            "numberVal": {
                              "value": 18
                            }
                          }
                        },
                        "editorId": "icon18"
                      },
                      {
                        "type": "expanded",
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Most Oobli users in Nairobi start with 'Kill the Debt' to save on interest."
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "body_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "text46"
                          }
                        ],
                        "editorId": "expanded10"
                      }
                    ],
                    "editorId": "row28"
                  }
                ],
                "editorId": "container43"
              },
              {
                "type": "@std.button",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Continue to Oobli Plans"
                    }
                  },
                  "variant": {
                    "stringVal": {
                      "value": "primary"
                    }
                  },
                  "size": {
                    "stringVal": {
                      "value": "large"
                    }
                  },
                  "full_width": {
                    "boolVal": {
                      "value": true
                    }
                  }
                },
                "editorId": "stdbutton6"
              }
            ],
            "editorId": "column30"
          }
        ],
        "editorId": "column26"
      }
    ],
    "editorId": "scaffold3"
  }
}
```

### 4. Oobli Says... Dashboard

- Frame ID: `frame10`
- Original page prompt: "Main feed showing daily spending, M-Pesa summaries, and AI insights"
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "scroll": {
            "boolVal": {
              "value": true
            }
          },
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "lg",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Oobli says..."
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_medium"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 900
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text47"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Your spending is 12% lower than last Tuesday"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "body_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_background"
                            }
                          }
                        },
                        "editorId": "text48"
                      }
                    ],
                    "editorId": "column32"
                  },
                  {
                    "type": "avatar",
                    "properties": {
                      "text": {
                        "stringVal": {
                          "value": "JD"
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "primary"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "on_primary"
                        }
                      },
                      "size": {
                        "numberVal": {
                          "value": 40
                        }
                      }
                    },
                    "editorId": "avatar1"
                  }
                ],
                "editorId": "row29"
              }
            ],
            "editorId": "container44"
          },
          {
            "type": "container",
            "properties": {
              "margin": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "lg",
                  "bottomToken": "lg"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "rightToken": "lg",
                  "leftToken": "lg"
                }
              }
            },
            "children": [
              {
                "type": "container",
                "properties": {
                  "bg": {
                    "color": {
                      "color": "surface"
                    }
                  },
                  "radius": {
                    "radius": {
                      "topLeft": 0,
                      "topRight": 0,
                      "bottomLeft": 0,
                      "bottomRight": 0,
                      "token": "xl"
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "shadow": {
                    "stringVal": {
                      "value": "sm"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "align": {
                            "align": {
                              "named": "space_between"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Today's Flow"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "title_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "text49"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "KES 4,250.00"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "title_large"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary_text"
                                }
                              }
                            },
                            "editorId": "text50"
                          }
                        ],
                        "editorId": "row30"
                      },
                      {
                        "type": "container",
                        "properties": {
                          "height": {
                            "px": {
                              "value": 120,
                              "isInfinity": false
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "bar_chart",
                            "properties": {
                              "data": {
                                "stringVal": {
                                  "value": "1200,800,2400,1800,900,3100,4250"
                                }
                              },
                              "labels": {
                                "stringVal": {
                                  "value": "M,T,W,T,F,S,S"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary"
                                }
                              },
                              "bar_radius": {
                                "numberVal": {
                                  "value": 4
                                }
                              },
                              "animate": {
                                "boolVal": {
                                  "value": true
                                }
                              }
                            },
                            "editorId": "barchart1"
                          }
                        ],
                        "editorId": "container47"
                      }
                    ],
                    "editorId": "column33"
                  }
                ],
                "editorId": "container46"
              }
            ],
            "editorId": "container45"
          },
          {
            "type": "column",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "rightToken": "lg",
                  "leftToken": "lg"
                }
              },
              "spacing": {
                "stringVal": {
                  "value": "md"
                }
              }
            },
            "children": [
              {
                "type": "@insight_card",
                "properties": {
                  "title": {
                    "stringVal": {
                      "value": "Subscription Alert"
                    }
                  },
                  "body": {
                    "stringVal": {
                      "value": "Oobli noticed a KES 1,500 payment to Netflix. You haven't used the app in 14 days. Cancel?"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "notifications_active_rounded"
                    }
                  },
                  "tone": {
                    "stringVal": {
                      "value": "warning"
                    }
                  }
                },
                "editorId": "insightcard1"
              },
              {
                "type": "@insight_card",
                "properties": {
                  "title": {
                    "stringVal": {
                      "value": "Spending Pattern"
                    }
                  },
                  "body": {
                    "stringVal": {
                      "value": "You typically spend KES 800 on 'Pochi la Biashara' on Wednesdays. You've already spent KES 1,200 today."
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "insights_rounded"
                    }
                  },
                  "tone": {
                    "stringVal": {
                      "value": "primary"
                    }
                  }
                },
                "editorId": "insightcard2"
              }
            ],
            "editorId": "column34"
          },
          {
            "type": "container",
            "properties": {
              "margin": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "lg"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "radius": {
                "radius": {
                  "topLeft": 0,
                  "topRight": 0,
                  "bottomLeft": 0,
                  "bottomRight": 0,
                  "topLeftToken": "lg",
                  "topRightToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Recent M-Pesa"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_medium"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text51"
                      },
                      {
                        "type": "@std.button",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Add Manual"
                            }
                          },
                          "variant": {
                            "stringVal": {
                              "value": "outline"
                            }
                          },
                          "size": {
                            "stringVal": {
                              "value": "small"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "add"
                            }
                          }
                        },
                        "editorId": "stdbutton7"
                      }
                    ],
                    "editorId": "row31"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "numberVal": {
                          "value": 0
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@transaction_item",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Mama Mboga - Pochi"
                            }
                          },
                          "category": {
                            "stringVal": {
                              "value": "Food"
                            }
                          },
                          "amount": {
                            "stringVal": {
                              "value": "- KES 450"
                            }
                          },
                          "time": {
                            "stringVal": {
                              "value": "10:45 AM"
                            }
                          },
                          "is_ai_fix": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "transactionitem1"
                      },
                      {
                        "type": "divider",
                        "properties": {
                          "thickness": {
                            "numberVal": {
                              "value": 1
                            }
                          },
                          "color": {
                            "color": {
                              "color": "divider"
                            }
                          }
                        },
                        "editorId": "divider1"
                      },
                      {
                        "type": "@transaction_item",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Super Metro - Till"
                            }
                          },
                          "category": {
                            "stringVal": {
                              "value": "Transport"
                            }
                          },
                          "amount": {
                            "stringVal": {
                              "value": "- KES 100"
                            }
                          },
                          "time": {
                            "stringVal": {
                              "value": "08:15 AM"
                            }
                          }
                        },
                        "editorId": "transactionitem2"
                      },
                      {
                        "type": "divider",
                        "properties": {
                          "thickness": {
                            "numberVal": {
                              "value": 1
                            }
                          },
                          "color": {
                            "color": {
                              "color": "divider"
                            }
                          }
                        },
                        "editorId": "divider2"
                      },
                      {
                        "type": "@transaction_item",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Naivas Paybill"
                            }
                          },
                          "category": {
                            "stringVal": {
                              "value": "Shopping"
                            }
                          },
                          "amount": {
                            "stringVal": {
                              "value": "- KES 2,100"
                            }
                          },
                          "time": {
                            "stringVal": {
                              "value": "Yesterday"
                            }
                          }
                        },
                        "editorId": "transactionitem3"
                      },
                      {
                        "type": "divider",
                        "properties": {
                          "thickness": {
                            "numberVal": {
                              "value": 1
                            }
                          },
                          "color": {
                            "color": {
                              "color": "divider"
                            }
                          }
                        },
                        "editorId": "divider3"
                      },
                      {
                        "type": "@transaction_item",
                        "properties": {
                          "name": {
                            "stringVal": {
                              "value": "Sent to Alex"
                            }
                          },
                          "category": {
                            "stringVal": {
                              "value": "Transfer"
                            }
                          },
                          "amount": {
                            "stringVal": {
                              "value": "- KES 5,000"
                            }
                          },
                          "time": {
                            "stringVal": {
                              "value": "Yesterday"
                            }
                          },
                          "is_ai_fix": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "transactionitem4"
                      }
                    ],
                    "editorId": "column36"
                  }
                ],
                "editorId": "column35"
              }
            ],
            "editorId": "container48"
          },
          {
            "type": "sizedbox",
            "properties": {
              "height": {
                "px": {
                  "value": 80,
                  "isInfinity": false
                }
              }
            },
            "editorId": "sizedbox5"
          }
        ],
        "editorId": "column31"
      },
      {
        "type": "fab",
        "properties": {
          "icon": {
            "icon": {
              "name": "auto_awesome_rounded"
            }
          },
          "label": {
            "stringVal": {
              "value": "Ask Oobli"
            }
          },
          "bg": {
            "color": {
              "color": "primary"
            }
          },
          "color": {
            "color": {
              "color": "on_primary"
            }
          }
        },
        "editorId": "fab1"
      },
      {
        "type": "container",
        "properties": {
          "align": {
            "align": {
              "named": "bottom"
            }
          }
        },
        "children": [
          {
            "type": "@std.bottom_nav",
            "children": [
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "dashboard"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Oobli Says"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "auto_awesome_rounded"
                    }
                  },
                  "selected": {
                    "boolVal": {
                      "value": true
                    }
                  }
                },
                "editorId": "stdnavitem1"
              },
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "planning"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Plans"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "event_note_rounded"
                    }
                  }
                },
                "editorId": "stdnavitem2"
              },
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "goals"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Goals"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "track_changes_rounded"
                    }
                  }
                },
                "editorId": "stdnavitem3"
              },
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "wrapped"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Wrapped"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "inventory_2_rounded"
                    }
                  }
                },
                "editorId": "stdnavitem4"
              }
            ],
            "editorId": "stdbottomnav1"
          }
        ],
        "editorId": "container49"
      }
    ],
    "editorId": "scaffold4"
  }
}
```

### 5. Transaction History

- Frame ID: `frame6`
- Original page prompt: "A list of parsed SMS transactions with options to edit categories and allocations"
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "lg",
                  "rightToken": "lg",
                  "bottomToken": "md",
                  "leftToken": "lg"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "arrow_back_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "iconbutton3"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Activity"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_medium"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text52"
                      },
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "search_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "iconbutton4"
                      }
                    ],
                    "editorId": "row32"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "primary",
                          "opacityPercent": 8
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "lg"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "md"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 1,
                          "color": "primary/20"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "row",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "container",
                            "properties": {
                              "width": {
                                "px": {
                                  "value": 42,
                                  "isInfinity": false
                                }
                              },
                              "height": {
                                "px": {
                                  "value": 42,
                                  "isInfinity": false
                                }
                              },
                              "radius": {
                                "radius": {
                                  "topLeft": 0,
                                  "topRight": 0,
                                  "bottomLeft": 0,
                                  "bottomRight": 0,
                                  "token": "full"
                                }
                              },
                              "bg": {
                                "color": {
                                  "color": "primary"
                                }
                              },
                              "align_child": {
                                "align": {
                                  "named": "center"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "icon",
                                "properties": {
                                  "name": {
                                    "icon": {
                                      "name": "face_6_rounded"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "on_surface"
                                    }
                                  },
                                  "size": {
                                    "numberVal": {
                                      "value": 26
                                    }
                                  }
                                },
                                "editorId": "icon19"
                              }
                            ],
                            "editorId": "container52"
                          },
                          {
                            "type": "expanded",
                            "children": [
                              {
                                "type": "column",
                                "properties": {
                                  "spacing": {
                                    "stringVal": {
                                      "value": "xs"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "Oobli says..."
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "label_large"
                                        }
                                      },
                                      "font_weight": {
                                        "stringVal": {
                                          "value": "bold"
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "on_surface"
                                        }
                                      }
                                    },
                                    "editorId": "text53"
                                  },
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "You've spent 15% more on Groceries this week than your AI plan suggested."
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "body_small"
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "primary_text"
                                        }
                                      },
                                      "max_lines": {
                                        "numberVal": {
                                          "value": 2
                                        }
                                      }
                                    },
                                    "editorId": "text54"
                                  }
                                ],
                                "editorId": "column39"
                              }
                            ],
                            "editorId": "expanded11"
                          }
                        ],
                        "editorId": "row33"
                      }
                    ],
                    "editorId": "container51"
                  }
                ],
                "editorId": "column38"
              }
            ],
            "editorId": "container50"
          },
          {
            "type": "expanded",
            "children": [
              {
                "type": "column",
                "properties": {
                  "scroll": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "TODAY"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text55"
                      },
                      {
                        "type": "@transaction_card",
                        "properties": {
                          "merchant": {
                            "stringVal": {
                              "value": "Naivas Supermarket"
                            }
                          },
                          "category": {
                            "stringVal": {
                              "value": "Groceries"
                            }
                          },
                          "amount": {
                            "stringVal": {
                              "value": "-KES 4,250"
                            }
                          },
                          "time": {
                            "stringVal": {
                              "value": "14:20"
                            }
                          },
                          "ref": {
                            "stringVal": {
                              "value": "RL82XJ91"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "shopping_cart_rounded"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "success"
                            }
                          }
                        },
                        "editorId": "transactioncard1"
                      },
                      {
                        "type": "@transaction_card",
                        "properties": {
                          "merchant": {
                            "stringVal": {
                              "value": "Mama Mboga Pochi"
                            }
                          },
                          "category": {
                            "stringVal": {
                              "value": "Food & Dining"
                            }
                          },
                          "amount": {
                            "stringVal": {
                              "value": "-KES 350"
                            }
                          },
                          "time": {
                            "stringVal": {
                              "value": "12:05"
                            }
                          },
                          "ref": {
                            "stringVal": {
                              "value": "RLJ29S11"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "restaurant_rounded"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "orange"
                            }
                          }
                        },
                        "editorId": "transactioncard2"
                      },
                      {
                        "type": "@transaction_card",
                        "properties": {
                          "merchant": {
                            "stringVal": {
                              "value": "KPLC Prepaid"
                            }
                          },
                          "category": {
                            "stringVal": {
                              "value": "Utilities"
                            }
                          },
                          "amount": {
                            "stringVal": {
                              "value": "-KES 1,000"
                            }
                          },
                          "time": {
                            "stringVal": {
                              "value": "09:15"
                            }
                          },
                          "ref": {
                            "stringVal": {
                              "value": "RLH01K22"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "bolt_rounded"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "accent"
                            }
                          }
                        },
                        "editorId": "transactioncard3"
                      }
                    ],
                    "editorId": "column41"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "YESTERDAY"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text56"
                      },
                      {
                        "type": "@transaction_card",
                        "properties": {
                          "merchant": {
                            "stringVal": {
                              "value": "Shell Service Station"
                            }
                          },
                          "category": {
                            "stringVal": {
                              "value": "Transport"
                            }
                          },
                          "amount": {
                            "stringVal": {
                              "value": "-KES 2,500"
                            }
                          },
                          "time": {
                            "stringVal": {
                              "value": "18:45"
                            }
                          },
                          "ref": {
                            "stringVal": {
                              "value": "RKP92M10"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "local_gas_station_rounded"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "info"
                            }
                          }
                        },
                        "editorId": "transactioncard4"
                      },
                      {
                        "type": "container",
                        "properties": {
                          "bg": {
                            "color": {
                              "color": "surface"
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 0,
                              "topRight": 0,
                              "bottomLeft": 0,
                              "bottomRight": 0,
                              "token": "lg"
                            }
                          },
                          "padding": {
                            "edgeInsets": {
                              "top": 0,
                              "right": 0,
                              "bottom": 0,
                              "left": 0,
                              "token": "md"
                            }
                          },
                          "border": {
                            "border": {
                              "width": 2,
                              "color": "primary/30"
                            }
                          },
                          "shadow": {
                            "stringVal": {
                              "value": "sm"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "column",
                            "properties": {
                              "spacing": {
                                "stringVal": {
                                  "value": "md"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "row",
                                "properties": {
                                  "spacing": {
                                    "stringVal": {
                                      "value": "md"
                                    }
                                  },
                                  "cross_align": {
                                    "align": {
                                      "named": "center"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "container",
                                    "properties": {
                                      "width": {
                                        "px": {
                                          "value": 48,
                                          "isInfinity": false
                                        }
                                      },
                                      "height": {
                                        "px": {
                                          "value": 48,
                                          "isInfinity": false
                                        }
                                      },
                                      "radius": {
                                        "radius": {
                                          "topLeft": 0,
                                          "topRight": 0,
                                          "bottomLeft": 0,
                                          "bottomRight": 0,
                                          "token": "md"
                                        }
                                      },
                                      "bg": {
                                        "color": {
                                          "color": "warning",
                                          "opacityPercent": 12
                                        }
                                      },
                                      "align_child": {
                                        "align": {
                                          "named": "center"
                                        }
                                      }
                                    },
                                    "children": [
                                      {
                                        "type": "icon",
                                        "properties": {
                                          "name": {
                                            "icon": {
                                              "name": "person_rounded"
                                            }
                                          },
                                          "color": {
                                            "color": {
                                              "color": "on_surface"
                                            }
                                          },
                                          "size": {
                                            "numberVal": {
                                              "value": 24
                                            }
                                          }
                                        },
                                        "editorId": "icon20"
                                      }
                                    ],
                                    "editorId": "container54"
                                  },
                                  {
                                    "type": "expanded",
                                    "children": [
                                      {
                                        "type": "column",
                                        "properties": {
                                          "spacing": {
                                            "stringVal": {
                                              "value": "xs"
                                            }
                                          }
                                        },
                                        "children": [
                                          {
                                            "type": "row",
                                            "properties": {
                                              "align": {
                                                "align": {
                                                  "named": "space_between"
                                                }
                                              }
                                            },
                                            "children": [
                                              {
                                                "type": "text",
                                                "properties": {
                                                  "content": {
                                                    "stringVal": {
                                                      "value": "John Kamau"
                                                    }
                                                  },
                                                  "style": {
                                                    "textStyle": {
                                                      "styleName": "title_small"
                                                    }
                                                  },
                                                  "font_weight": {
                                                    "stringVal": {
                                                      "value": "bold"
                                                    }
                                                  },
                                                  "color": {
                                                    "color": {
                                                      "color": "primary_text"
                                                    }
                                                  }
                                                },
                                                "editorId": "text57"
                                              },
                                              {
                                                "type": "text",
                                                "properties": {
                                                  "content": {
                                                    "stringVal": {
                                                      "value": "-KES 1,200"
                                                    }
                                                  },
                                                  "style": {
                                                    "textStyle": {
                                                      "styleName": "title_small"
                                                    }
                                                  },
                                                  "font_weight": {
                                                    "stringVal": {
                                                      "value": "bold"
                                                    }
                                                  },
                                                  "color": {
                                                    "color": {
                                                      "color": "primary_text"
                                                    }
                                                  }
                                                },
                                                "editorId": "text58"
                                              }
                                            ],
                                            "editorId": "row35"
                                          },
                                          {
                                            "type": "text",
                                            "properties": {
                                              "content": {
                                                "stringVal": {
                                                  "value": "Sent to someone • 10:30"
                                                }
                                              },
                                              "style": {
                                                "textStyle": {
                                                  "styleName": "label_small"
                                                }
                                              },
                                              "color": {
                                                "color": {
                                                  "color": "on_surface"
                                                }
                                              }
                                            },
                                            "editorId": "text59"
                                          }
                                        ],
                                        "editorId": "column44"
                                      }
                                    ],
                                    "editorId": "expanded13"
                                  }
                                ],
                                "editorId": "row34"
                              },
                              {
                                "type": "divider",
                                "properties": {
                                  "thickness": {
                                    "numberVal": {
                                      "value": 1
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "divider"
                                    }
                                  }
                                },
                                "editorId": "divider4"
                              },
                              {
                                "type": "row",
                                "properties": {
                                  "align": {
                                    "align": {
                                      "named": "space_between"
                                    }
                                  },
                                  "cross_align": {
                                    "align": {
                                      "named": "center"
                                    }
                                  }
                                },
                                "children": [
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "Is this 'Groceries'?"
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "body_small"
                                        }
                                      },
                                      "font_weight": {
                                        "stringVal": {
                                          "value": "bold"
                                        }
                                      },
                                      "color": {
                                        "color": {
                                          "color": "on_surface"
                                        }
                                      }
                                    },
                                    "editorId": "text60"
                                  },
                                  {
                                    "type": "row",
                                    "properties": {
                                      "spacing": {
                                        "stringVal": {
                                          "value": "sm"
                                        }
                                      }
                                    },
                                    "children": [
                                      {
                                        "type": "@std.button",
                                        "properties": {
                                          "content": {
                                            "stringVal": {
                                              "value": "Edit"
                                            }
                                          },
                                          "variant": {
                                            "stringVal": {
                                              "value": "outline"
                                            }
                                          },
                                          "size": {
                                            "stringVal": {
                                              "value": "small"
                                            }
                                          }
                                        },
                                        "editorId": "stdbutton8"
                                      },
                                      {
                                        "type": "@std.button",
                                        "properties": {
                                          "content": {
                                            "stringVal": {
                                              "value": "Yes"
                                            }
                                          },
                                          "variant": {
                                            "stringVal": {
                                              "value": "primary"
                                            }
                                          },
                                          "size": {
                                            "stringVal": {
                                              "value": "small"
                                            }
                                          }
                                        },
                                        "editorId": "stdbutton9"
                                      }
                                    ],
                                    "editorId": "row37"
                                  }
                                ],
                                "editorId": "row36"
                              }
                            ],
                            "editorId": "column43"
                          }
                        ],
                        "editorId": "container53"
                      }
                    ],
                    "editorId": "column42"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "stretch"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "24 OCT"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text61"
                      },
                      {
                        "type": "@transaction_card",
                        "properties": {
                          "merchant": {
                            "stringVal": {
                              "value": "Netflix"
                            }
                          },
                          "category": {
                            "stringVal": {
                              "value": "Entertainment"
                            }
                          },
                          "amount": {
                            "stringVal": {
                              "value": "-KES 1,100"
                            }
                          },
                          "time": {
                            "stringVal": {
                              "value": "00:01"
                            }
                          },
                          "ref": {
                            "stringVal": {
                              "value": "RKF11L99"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "subscriptions_rounded"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "error"
                            }
                          }
                        },
                        "editorId": "transactioncard5"
                      }
                    ],
                    "editorId": "column45"
                  }
                ],
                "editorId": "column40"
              }
            ],
            "editorId": "expanded12"
          },
          {
            "type": "container",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "gradient": {
                "gradient": {
                  "type": "GRADIENT_TYPE_LINEAR",
                  "direction": "to_top",
                  "stops": [
                    {
                      "color": "background"
                    },
                    {
                      "color": "transparent"
                    }
                  ]
                }
              }
            },
            "children": [
              {
                "type": "@std.button",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Add Transaction"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "add_rounded"
                    }
                  },
                  "full_width": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "size": {
                    "stringVal": {
                      "value": "large"
                    }
                  }
                },
                "editorId": "stdbutton10"
              }
            ],
            "editorId": "container55"
          }
        ],
        "editorId": "column37"
      }
    ],
    "editorId": "scaffold5"
  }
}
```

### 6. Oobli Analytics

- Frame ID: `frame9`
- Original page prompt: "Minimalist charts and graphs showing spending across Tills, Paybills, and Pochi"
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "scroll": {
            "boolVal": {
              "value": true
            }
          },
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "bg": {
                "color": {
                  "color": "surface"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "start"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Oobli Analytics"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_medium"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 800
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text62"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Insights from your M-Pesa & Banks"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "body_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text63"
                      }
                    ],
                    "editorId": "column47"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "width": {
                        "px": {
                          "value": 48,
                          "isInfinity": false
                        }
                      },
                      "height": {
                        "px": {
                          "value": 48,
                          "isInfinity": false
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "full"
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "secondary_background"
                        }
                      },
                      "align_child": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "icon",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "auto_awesome_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_surface"
                            }
                          },
                          "size": {
                            "numberVal": {
                              "value": 24
                            }
                          }
                        },
                        "editorId": "icon21"
                      }
                    ],
                    "editorId": "container57"
                  }
                ],
                "editorId": "row38"
              }
            ],
            "editorId": "container56"
          },
          {
            "type": "container",
            "properties": {
              "margin": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "radius": {
                "radius": {
                  "topLeft": 0,
                  "topRight": 0,
                  "bottomLeft": 0,
                  "bottomRight": 0,
                  "token": "xl"
                }
              },
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "shadow": {
                "stringVal": {
                  "value": "sm"
                }
              },
              "border": {
                "border": {
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Spending Flow"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_medium"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text64"
                      },
                      {
                        "type": "dropdown",
                        "properties": {
                          "options": {
                            "stringVal": {
                              "value": "This Week,Last Month,Yearly"
                            }
                          },
                          "value": {
                            "stringVal": {
                              "value": "This Week"
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 0,
                              "topRight": 0,
                              "bottomLeft": 0,
                              "bottomRight": 0,
                              "token": "md"
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "secondary_background"
                            }
                          },
                          "expanded": {
                            "expanded": {
                              "enabled": true,
                              "flex": 1
                            }
                          }
                        },
                        "editorId": "dropdown1"
                      }
                    ],
                    "editorId": "row39"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "height": {
                        "px": {
                          "value": 200,
                          "isInfinity": false
                        }
                      },
                      "align_child": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "line_chart",
                        "properties": {
                          "data": {
                            "stringVal": {
                              "value": "1200,4500,2100,8900,3200,5600,4100"
                            }
                          },
                          "labels": {
                            "stringVal": {
                              "value": "M,T,W,T,F,S,S"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary"
                            }
                          },
                          "curved": {
                            "boolVal": {
                              "value": true
                            }
                          },
                          "filled": {
                            "boolVal": {
                              "value": true
                            }
                          },
                          "fill_opacity": {
                            "numberVal": {
                              "value": 0.1
                            }
                          },
                          "line_width": {
                            "numberVal": {
                              "value": 3
                            }
                          },
                          "show_dots": {
                            "boolVal": {
                              "value": true
                            }
                          }
                        },
                        "editorId": "linechart1"
                      }
                    ],
                    "editorId": "container59"
                  },
                  {
                    "type": "divider",
                    "properties": {
                      "thickness": {
                        "numberVal": {
                          "value": 1
                        }
                      },
                      "color": {
                        "color": {
                          "color": "divider"
                        }
                      }
                    },
                    "editorId": "divider5"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@category_chip",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "Paybill"
                            }
                          },
                          "value": {
                            "stringVal": {
                              "value": "KES 14.2k"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "primary"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "receipt_long_rounded"
                            }
                          }
                        },
                        "editorId": "categorychip1"
                      },
                      {
                        "type": "@category_chip",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "Tills"
                            }
                          },
                          "value": {
                            "stringVal": {
                              "value": "KES 8.4k"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "success"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "store_rounded"
                            }
                          }
                        },
                        "editorId": "categorychip2"
                      },
                      {
                        "type": "@category_chip",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "Pochi"
                            }
                          },
                          "value": {
                            "stringVal": {
                              "value": "KES 3.1k"
                            }
                          },
                          "tone": {
                            "stringVal": {
                              "value": "accent"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "account_balance_wallet_rounded"
                            }
                          }
                        },
                        "editorId": "categorychip3"
                      }
                    ],
                    "editorId": "row40"
                  }
                ],
                "editorId": "column48"
              }
            ],
            "editorId": "container58"
          },
          {
            "type": "container",
            "properties": {
              "margin": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "topToken": "lg",
                  "bottomToken": "lg"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "bg": {
                "color": {
                  "color": "primary_container",
                  "opacityPercent": 30
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "start"
                    }
                  }
                },
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "width": {
                        "px": {
                          "value": 50,
                          "isInfinity": false
                        }
                      },
                      "height": {
                        "px": {
                          "value": 50,
                          "isInfinity": false
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "full"
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "primary"
                        }
                      },
                      "align_child": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "O"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_surface"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 900
                            }
                          }
                        },
                        "editorId": "text65"
                      }
                    ],
                    "editorId": "container61"
                  },
                  {
                    "type": "expanded",
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "sm"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Oobli says..."
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_large"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "on_primary"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text66"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "You've spent 24% more on Tills this week compared to last. Most of this went to 'Mama Mboga' - should we re-categorize this as Groceries?"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "body_medium"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "on_primary"
                                }
                              }
                            },
                            "editorId": "text67"
                          },
                          {
                            "type": "row",
                            "properties": {
                              "spacing": {
                                "stringVal": {
                                  "value": "sm"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "@std.button",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Yes, Recategorize"
                                    }
                                  },
                                  "size": {
                                    "stringVal": {
                                      "value": "small"
                                    }
                                  }
                                },
                                "editorId": "stdbutton11"
                              },
                              {
                                "type": "@std.button",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "Keep as Transfer"
                                    }
                                  },
                                  "variant": {
                                    "stringVal": {
                                      "value": "ghost"
                                    }
                                  },
                                  "size": {
                                    "stringVal": {
                                      "value": "small"
                                    }
                                  }
                                },
                                "editorId": "stdbutton12"
                              }
                            ],
                            "editorId": "row42"
                          }
                        ],
                        "editorId": "column49"
                      }
                    ],
                    "editorId": "expanded14"
                  }
                ],
                "editorId": "row41"
              }
            ],
            "editorId": "container60"
          },
          {
            "type": "column",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "spacing": {
                "stringVal": {
                  "value": "md"
                }
              },
              "cross_align": {
                "align": {
                  "named": "stretch"
                }
              }
            },
            "children": [
              {
                "type": "text",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Distribution"
                    }
                  },
                  "style": {
                    "textStyle": {
                      "styleName": "title_medium"
                    }
                  },
                  "font_weight": {
                    "stringVal": {
                      "value": "bold"
                    }
                  }
                },
                "editorId": "text68"
              },
              {
                "type": "container",
                "properties": {
                  "bg": {
                    "color": {
                      "color": "surface"
                    }
                  },
                  "radius": {
                    "radius": {
                      "topLeft": 0,
                      "topRight": 0,
                      "bottomLeft": 0,
                      "bottomRight": 0,
                      "token": "lg"
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "border": {
                    "border": {
                      "width": 1,
                      "color": "divider"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "lg"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@std.pie_chart",
                        "properties": {
                          "variant": {
                            "stringVal": {
                              "value": "donut"
                            }
                          },
                          "size": {
                            "stringVal": {
                              "value": "medium"
                            }
                          },
                          "legend": {
                            "stringVal": {
                              "value": "right"
                            }
                          },
                          "data": {
                            "stringVal": {
                              "value": "55,30,15"
                            }
                          },
                          "labels": {
                            "stringVal": {
                              "value": "Merchant Tills,Paybills,Pochi la Biashara"
                            }
                          },
                          "colors": {
                            "stringVal": {
                              "value": "primary,success,accent"
                            }
                          },
                          "ring": {
                            "stringVal": {
                              "value": "thick"
                            }
                          },
                          "gap": {
                            "stringVal": {
                              "value": "normal"
                            }
                          }
                        },
                        "editorId": "stdpiechart1"
                      },
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "row",
                            "properties": {
                              "spacing": {
                                "stringVal": {
                                  "value": "md"
                                }
                              },
                              "cross_align": {
                                "align": {
                                  "named": "center"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "icon",
                                "properties": {
                                  "name": {
                                    "icon": {
                                      "name": "shopping_cart_rounded"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "on_surface"
                                    }
                                  }
                                },
                                "editorId": "icon22"
                              },
                              {
                                "type": "expanded",
                                "children": [
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "Supermarkets (Paybill)"
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "body_medium"
                                        }
                                      }
                                    },
                                    "editorId": "text69"
                                  }
                                ],
                                "editorId": "expanded15"
                              },
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "KES 7,200"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "body_medium"
                                    }
                                  },
                                  "font_weight": {
                                    "stringVal": {
                                      "value": "bold"
                                    }
                                  }
                                },
                                "editorId": "text70"
                              }
                            ],
                            "editorId": "row43"
                          },
                          {
                            "type": "divider",
                            "properties": {
                              "color": {
                                "color": {
                                  "color": "divider"
                                }
                              }
                            },
                            "editorId": "divider6"
                          },
                          {
                            "type": "row",
                            "properties": {
                              "spacing": {
                                "stringVal": {
                                  "value": "md"
                                }
                              },
                              "cross_align": {
                                "align": {
                                  "named": "center"
                                }
                              }
                            },
                            "children": [
                              {
                                "type": "icon",
                                "properties": {
                                  "name": {
                                    "icon": {
                                      "name": "restaurant_rounded"
                                    }
                                  },
                                  "color": {
                                    "color": {
                                      "color": "on_surface"
                                    }
                                  }
                                },
                                "editorId": "icon23"
                              },
                              {
                                "type": "expanded",
                                "children": [
                                  {
                                    "type": "text",
                                    "properties": {
                                      "content": {
                                        "stringVal": {
                                          "value": "Dining (Tills)"
                                        }
                                      },
                                      "style": {
                                        "textStyle": {
                                          "styleName": "body_medium"
                                        }
                                      }
                                    },
                                    "editorId": "text71"
                                  }
                                ],
                                "editorId": "expanded16"
                              },
                              {
                                "type": "text",
                                "properties": {
                                  "content": {
                                    "stringVal": {
                                      "value": "KES 4,150"
                                    }
                                  },
                                  "style": {
                                    "textStyle": {
                                      "styleName": "body_medium"
                                    }
                                  },
                                  "font_weight": {
                                    "stringVal": {
                                      "value": "bold"
                                    }
                                  }
                                },
                                "editorId": "text72"
                              }
                            ],
                            "editorId": "row44"
                          }
                        ],
                        "editorId": "column52"
                      }
                    ],
                    "editorId": "column51"
                  }
                ],
                "editorId": "container62"
              }
            ],
            "editorId": "column50"
          },
          {
            "type": "container",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "margin": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "bottomToken": "lg"
                }
              }
            },
            "children": [
              {
                "type": "@std.button",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Generate AI Spending Plan"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "auto_graph_rounded"
                    }
                  },
                  "full_width": {
                    "boolVal": {
                      "value": true
                    }
                  },
                  "size": {
                    "stringVal": {
                      "value": "large"
                    }
                  }
                },
                "editorId": "stdbutton13"
              }
            ],
            "editorId": "container63"
          }
        ],
        "editorId": "column46"
      }
    ],
    "editorId": "scaffold6"
  }
}
```

### 7. Oobli Plans

- Frame ID: `frame4`
- Original page prompt: "AI-powered planning page to input anticipated income and generate a budget"
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "scroll": {
            "boolVal": {
              "value": true
            }
          },
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "bg": {
                "color": {
                  "color": "secondary_background"
                }
              },
              "radius": {
                "radius": {
                  "topLeft": 0,
                  "topRight": 0,
                  "bottomLeft": 32,
                  "bottomRight": 32
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "arrow_back_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "iconbutton5"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Oobli Plans"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_large"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text73"
                      },
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "auto_awesome_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary"
                            }
                          }
                        },
                        "editorId": "iconbutton6"
                      }
                    ],
                    "editorId": "row45"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "xl"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "lg"
                        }
                      },
                      "shadow": {
                        "stringVal": {
                          "value": "sm"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "md"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Oobli says..."
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_large"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "on_surface"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text74"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Tell me what you're expecting this month, and I'll draft a plan for you."
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "body_medium"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "text75"
                          },
                          {
                            "type": "@std.textfield",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Anticipated Income"
                                }
                              },
                              "hint": {
                                "stringVal": {
                                  "value": "KES 85,000"
                                }
                              },
                              "leading_icon": {
                                "stringVal": {
                                  "value": "payments_rounded"
                                }
                              },
                              "variant": {
                                "stringVal": {
                                  "value": "filled"
                                }
                              }
                            },
                            "editorId": "stdtextfield1"
                          },
                          {
                            "type": "@std.textfield",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Main Goal"
                                }
                              },
                              "hint": {
                                "stringVal": {
                                  "value": "Save for a new laptop"
                                }
                              },
                              "leading_icon": {
                                "stringVal": {
                                  "value": "star_rounded"
                                }
                              },
                              "variant": {
                                "stringVal": {
                                  "value": "filled"
                                }
                              }
                            },
                            "editorId": "stdtextfield2"
                          },
                          {
                            "type": "@std.button",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Generate AI Plan"
                                }
                              },
                              "icon": {
                                "stringVal": {
                                  "value": "magic_button"
                                }
                              },
                              "full_width": {
                                "boolVal": {
                                  "value": true
                                }
                              }
                            },
                            "editorId": "stdbutton14"
                          }
                        ],
                        "editorId": "column55"
                      }
                    ],
                    "editorId": "container65"
                  }
                ],
                "editorId": "column54"
              }
            ],
            "editorId": "container64"
          },
          {
            "type": "column",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "spacing": {
                "stringVal": {
                  "value": "md"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "align": {
                    "align": {
                      "named": "space_between"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "August Draft Plan"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_small"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text76"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Based on your M-Pesa history"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "body_small"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "secondary_text"
                            }
                          }
                        },
                        "editorId": "text77"
                      }
                    ],
                    "editorId": "column57"
                  },
                  {
                    "type": "badge",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "AI Draft"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "accent"
                        }
                      },
                      "text_color": {
                        "color": {
                          "color": "on_accent"
                        }
                      }
                    },
                    "editorId": "badge1"
                  }
                ],
                "editorId": "row46"
              },
              {
                "type": "container",
                "properties": {
                  "height": {
                    "px": {
                      "value": 200,
                      "isInfinity": false
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "md"
                    }
                  },
                  "bg": {
                    "color": {
                      "color": "surface"
                    }
                  },
                  "radius": {
                    "radius": {
                      "topLeft": 0,
                      "topRight": 0,
                      "bottomLeft": 0,
                      "bottomRight": 0,
                      "token": "lg"
                    }
                  },
                  "border": {
                    "border": {
                      "width": 1,
                      "color": "divider"
                    }
                  }
                },
                "children": [
                  {
                    "type": "@std.pie_chart",
                    "properties": {
                      "variant": {
                        "stringVal": {
                          "value": "donut"
                        }
                      },
                      "data": {
                        "stringVal": {
                          "value": "50,20,20,10"
                        }
                      },
                      "labels": {
                        "stringVal": {
                          "value": "Needs,Savings,Wants,Emergency"
                        }
                      },
                      "colors": {
                        "stringVal": {
                          "value": "primary,success,accent,warning"
                        }
                      },
                      "ring": {
                        "stringVal": {
                          "value": "thick"
                        }
                      },
                      "legend": {
                        "stringVal": {
                          "value": "right"
                        }
                      },
                      "size": {
                        "stringVal": {
                          "value": "medium"
                        }
                      }
                    },
                    "editorId": "stdpiechart2"
                  }
                ],
                "editorId": "container66"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "@plan_item",
                    "properties": {
                      "category": {
                        "stringVal": {
                          "value": "Fixed Needs"
                        }
                      },
                      "amount": {
                        "stringVal": {
                          "value": "KES 42,500"
                        }
                      },
                      "reason": {
                        "stringVal": {
                          "value": "Rent, Utilities & Internet based on last month's Paybills."
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "home_rounded"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "primary"
                        }
                      }
                    },
                    "editorId": "planitem1"
                  },
                  {
                    "type": "@plan_item",
                    "properties": {
                      "category": {
                        "stringVal": {
                          "value": "Savings Goal"
                        }
                      },
                      "amount": {
                        "stringVal": {
                          "value": "KES 17,000"
                        }
                      },
                      "reason": {
                        "stringVal": {
                          "value": "Oobli suggests 20% to hit your laptop goal by December."
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "savings_rounded"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "success"
                        }
                      }
                    },
                    "editorId": "planitem2"
                  },
                  {
                    "type": "@plan_item",
                    "properties": {
                      "category": {
                        "stringVal": {
                          "value": "Flex Spending"
                        }
                      },
                      "amount": {
                        "stringVal": {
                          "value": "KES 17,000"
                        }
                      },
                      "reason": {
                        "stringVal": {
                          "value": "Dining and transport. You usually spend this at Tills."
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "shopping_cart_rounded"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "accent"
                        }
                      }
                    },
                    "editorId": "planitem3"
                  },
                  {
                    "type": "@plan_item",
                    "properties": {
                      "category": {
                        "stringVal": {
                          "value": "Emergency"
                        }
                      },
                      "amount": {
                        "stringVal": {
                          "value": "KES 8,500"
                        }
                      },
                      "reason": {
                        "stringVal": {
                          "value": "Safety net for unexpected M-Pesa requests."
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "verified_user_rounded"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "warning"
                        }
                      }
                    },
                    "editorId": "planitem4"
                  }
                ],
                "editorId": "column58"
              }
            ],
            "editorId": "column56"
          },
          {
            "type": "container",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "row",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "expanded",
                    "children": [
                      {
                        "type": "@std.button",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Edit Details"
                            }
                          },
                          "variant": {
                            "stringVal": {
                              "value": "outline"
                            }
                          }
                        },
                        "editorId": "stdbutton15"
                      }
                    ],
                    "editorId": "expanded17"
                  },
                  {
                    "type": "expanded",
                    "children": [
                      {
                        "type": "@std.button",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Activate Plan"
                            }
                          },
                          "variant": {
                            "stringVal": {
                              "value": "primary"
                            }
                          }
                        },
                        "editorId": "stdbutton16"
                      }
                    ],
                    "editorId": "expanded18"
                  }
                ],
                "editorId": "row47"
              }
            ],
            "editorId": "container67"
          },
          {
            "type": "container",
            "properties": {
              "align": {
                "align": {
                  "named": "bottom"
                }
              }
            },
            "children": [
              {
                "type": "@std.bottom_nav",
                "children": [
                  {
                    "type": "@std.nav_item",
                    "properties": {
                      "target": {
                        "stringVal": {
                          "value": "home"
                        }
                      },
                      "label": {
                        "stringVal": {
                          "value": "Feed"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "grid_view_rounded"
                        }
                      }
                    },
                    "editorId": "stdnavitem5"
                  },
                  {
                    "type": "@std.nav_item",
                    "properties": {
                      "target": {
                        "stringVal": {
                          "value": "plans"
                        }
                      },
                      "label": {
                        "stringVal": {
                          "value": "Plans"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "event_note_rounded"
                        }
                      },
                      "selected": {
                        "boolVal": {
                          "value": true
                        }
                      }
                    },
                    "editorId": "stdnavitem6"
                  },
                  {
                    "type": "@std.nav_item",
                    "properties": {
                      "target": {
                        "stringVal": {
                          "value": "goals"
                        }
                      },
                      "label": {
                        "stringVal": {
                          "value": "Goals"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "track_changes_rounded"
                        }
                      }
                    },
                    "editorId": "stdnavitem7"
                  },
                  {
                    "type": "@std.nav_item",
                    "properties": {
                      "target": {
                        "stringVal": {
                          "value": "wrapped"
                        }
                      },
                      "label": {
                        "stringVal": {
                          "value": "Wrapped"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "auto_graph_rounded"
                        }
                      }
                    },
                    "editorId": "stdnavitem8"
                  }
                ],
                "editorId": "stdbottomnav2"
              }
            ],
            "editorId": "container68"
          }
        ],
        "editorId": "column53"
      }
    ],
    "editorId": "scaffold7"
  }
}
```

### 8. Oobli Goals

- Frame ID: `frame8`
- Original page prompt: "A progress-tracking page for savings goals with visual milestones"
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "scroll": {
            "boolVal": {
              "value": true
            }
          },
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "border": {
                "borderSided": {
                  "side": "bottom",
                  "width": 1,
                  "color": "divider"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "sm"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Oobli Goals"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_medium"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 800
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text78"
                      },
                      {
                        "type": "avatar",
                        "properties": {
                          "text": {
                            "stringVal": {
                              "value": "AR"
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "secondary_background"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary"
                            }
                          },
                          "size": {
                            "numberVal": {
                              "value": 32
                            }
                          }
                        },
                        "editorId": "avatar2"
                      }
                    ],
                    "editorId": "row48"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "You're saving KSh 12,400 more than last month. Keep it up!"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "body_medium"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      }
                    },
                    "editorId": "text79"
                  }
                ],
                "editorId": "column60"
              }
            ],
            "editorId": "container69"
          },
          {
            "type": "column",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "spacing": {
                "stringVal": {
                  "value": "lg"
                }
              }
            },
            "children": [
              {
                "type": "text",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Primary Goal"
                    }
                  },
                  "style": {
                    "textStyle": {
                      "styleName": "label_large"
                    }
                  },
                  "color": {
                    "color": {
                      "color": "on_background"
                    }
                  },
                  "font_weight": {
                    "stringVal": {
                      "value": "bold"
                    }
                  }
                },
                "editorId": "text80"
              },
              {
                "type": "@goal_card",
                "properties": {
                  "title": {
                    "stringVal": {
                      "value": "New MacBook Pro"
                    }
                  },
                  "current": {
                    "stringVal": {
                      "value": "85000"
                    }
                  },
                  "target": {
                    "stringVal": {
                      "value": "240000"
                    }
                  },
                  "progress": {
                    "numberVal": {
                      "value": 0.35
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "laptop_mac_rounded"
                    }
                  },
                  "tone": {
                    "stringVal": {
                      "value": "primary"
                    }
                  }
                },
                "editorId": "goalcard1"
              },
              {
                "type": "container",
                "properties": {
                  "bg": {
                    "color": {
                      "color": "primary",
                      "opacityPercent": 5
                    }
                  },
                  "radius": {
                    "radius": {
                      "topLeft": 0,
                      "topRight": 0,
                      "bottomLeft": 0,
                      "bottomRight": 0,
                      "token": "lg"
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "md"
                    }
                  },
                  "border": {
                    "border": {
                      "width": 1,
                      "color": "primary/20"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "start"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Oobli says..."
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_small"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 800
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_surface"
                            }
                          }
                        },
                        "editorId": "text81"
                      },
                      {
                        "type": "expanded",
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "At your current M-Pesa save rate, you'll hit this goal by December! Want to boost it with a weekly KSh 500 sweep?"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "body_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary_text"
                                }
                              }
                            },
                            "editorId": "text82"
                          }
                        ],
                        "editorId": "expanded19"
                      }
                    ],
                    "editorId": "row49"
                  }
                ],
                "editorId": "container70"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "stretch"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Milestones"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "title_medium"
                        }
                      },
                      "font_weight": {
                        "stringVal": {
                          "value": "bold"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      }
                    },
                    "editorId": "text83"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "lg"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "lg"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 1,
                          "color": "divider"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "lg"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "@milestone_step",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Initial Deposit"
                                }
                              },
                              "date": {
                                "stringVal": {
                                  "value": "Oct 12"
                                }
                              },
                              "completed": {
                                "boolVal": {
                                  "value": true
                                }
                              }
                            },
                            "editorId": "milestonestep1"
                          },
                          {
                            "type": "@milestone_step",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Reach KSh 50,000"
                                }
                              },
                              "date": {
                                "stringVal": {
                                  "value": "Nov 02"
                                }
                              },
                              "completed": {
                                "boolVal": {
                                  "value": true
                                }
                              }
                            },
                            "editorId": "milestonestep2"
                          },
                          {
                            "type": "@milestone_step",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Halfway Mark"
                                }
                              },
                              "date": {
                                "stringVal": {
                                  "value": "In 2 months"
                                }
                              },
                              "completed": {
                                "boolVal": {
                                  "value": false
                                }
                              }
                            },
                            "editorId": "milestonestep3"
                          },
                          {
                            "type": "@milestone_step",
                            "properties": {
                              "label": {
                                "stringVal": {
                                  "value": "Final Purchase"
                                }
                              },
                              "date": {
                                "stringVal": {
                                  "value": "Dec 20"
                                }
                              },
                              "completed": {
                                "boolVal": {
                                  "value": false
                                }
                              }
                            },
                            "editorId": "milestonestep4"
                          }
                        ],
                        "editorId": "column63"
                      }
                    ],
                    "editorId": "container71"
                  }
                ],
                "editorId": "column62"
              },
              {
                "type": "text",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Other Goals"
                    }
                  },
                  "style": {
                    "textStyle": {
                      "styleName": "title_medium"
                    }
                  },
                  "font_weight": {
                    "stringVal": {
                      "value": "bold"
                    }
                  },
                  "color": {
                    "color": {
                      "color": "primary_text"
                    }
                  }
                },
                "editorId": "text84"
              },
              {
                "type": "row",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "container",
                    "properties": {
                      "expanded": {
                        "expanded": {
                          "enabled": true,
                          "flex": 1
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "lg"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "md"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 1,
                          "color": "divider"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "sm"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "start"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "flight_takeoff_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "on_surface"
                                }
                              },
                              "size": {
                                "numberVal": {
                                  "value": 20
                                }
                              }
                            },
                            "editorId": "icon24"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Coast Trip"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_large"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text85"
                          },
                          {
                            "type": "progress",
                            "properties": {
                              "value": {
                                "numberVal": {
                                  "value": 0.7
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "accent"
                                }
                              },
                              "thickness": {
                                "numberVal": {
                                  "value": 4
                                }
                              }
                            },
                            "editorId": "progress2"
                          }
                        ],
                        "editorId": "column64"
                      }
                    ],
                    "editorId": "container72"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "expanded": {
                        "expanded": {
                          "enabled": true,
                          "flex": 1
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "surface"
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "lg"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "md"
                        }
                      },
                      "border": {
                        "border": {
                          "width": 1,
                          "color": "divider"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "sm"
                            }
                          },
                          "cross_align": {
                            "align": {
                              "named": "start"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "emergency_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "on_surface"
                                }
                              },
                              "size": {
                                "numberVal": {
                                  "value": 20
                                }
                              }
                            },
                            "editorId": "icon25"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Emergency"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "label_large"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              }
                            },
                            "editorId": "text86"
                          },
                          {
                            "type": "progress",
                            "properties": {
                              "value": {
                                "numberVal": {
                                  "value": 0.15
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "success"
                                }
                              },
                              "thickness": {
                                "numberVal": {
                                  "value": 4
                                }
                              }
                            },
                            "editorId": "progress3"
                          }
                        ],
                        "editorId": "column65"
                      }
                    ],
                    "editorId": "container73"
                  }
                ],
                "editorId": "row50"
              },
              {
                "type": "@std.button",
                "properties": {
                  "content": {
                    "stringVal": {
                      "value": "Create New Goal"
                    }
                  },
                  "variant": {
                    "stringVal": {
                      "value": "outline"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "add_rounded"
                    }
                  },
                  "full_width": {
                    "boolVal": {
                      "value": true
                    }
                  }
                },
                "editorId": "stdbutton17"
              }
            ],
            "editorId": "column61"
          },
          {
            "type": "sizedbox",
            "properties": {
              "height": {
                "px": {
                  "value": 80,
                  "isInfinity": false
                }
              }
            },
            "editorId": "sizedbox6"
          }
        ],
        "editorId": "column59"
      },
      {
        "type": "container",
        "properties": {
          "align": {
            "align": {
              "named": "bottom"
            }
          }
        },
        "children": [
          {
            "type": "@std.bottom_nav",
            "children": [
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "home"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Feed"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "dashboard_rounded"
                    }
                  }
                },
                "editorId": "stdnavitem9"
              },
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "planning"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Plans"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "lightbulb_rounded"
                    }
                  }
                },
                "editorId": "stdnavitem10"
              },
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "goals"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Goals"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "auto_awesome_rounded"
                    }
                  },
                  "selected": {
                    "boolVal": {
                      "value": true
                    }
                  }
                },
                "editorId": "stdnavitem11"
              },
              {
                "type": "@std.nav_item",
                "properties": {
                  "target": {
                    "stringVal": {
                      "value": "wrapped"
                    }
                  },
                  "label": {
                    "stringVal": {
                      "value": "Wrapped"
                    }
                  },
                  "icon": {
                    "stringVal": {
                      "value": "inventory_2_rounded"
                    }
                  }
                },
                "editorId": "stdnavitem12"
              }
            ],
            "editorId": "stdbottomnav3"
          }
        ],
        "editorId": "container74"
      }
    ],
    "editorId": "scaffold8"
  }
}
```

### 9. Oobli Wrapped

- Frame ID: `frame5`
- Original page prompt: "A vibrant monthly recap of spending patterns and financial wins"
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "scroll": {
            "boolVal": {
              "value": true
            }
          },
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "bg": {
                "color": {
                  "color": "primary"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 32,
                  "right": 24,
                  "bottom": 32,
                  "left": 24
                }
              },
              "radius": {
                "radius": {
                  "topLeft": 0,
                  "topRight": 0,
                  "bottomLeft": 32,
                  "bottomRight": 32
                }
              },
              "gradient": {
                "gradient": {
                  "type": "GRADIENT_TYPE_LINEAR",
                  "direction": "to_bottom",
                  "stops": [
                    {
                      "color": "primary"
                    },
                    {
                      "color": "accent"
                    }
                  ]
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "lg"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "space_between"
                        }
                      },
                      "width": {
                        "px": {
                          "value": "Infinity",
                          "isInfinity": true
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "close_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_primary"
                            }
                          }
                        },
                        "editorId": "iconbutton7"
                      },
                      {
                        "type": "iconbutton",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "share_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_primary"
                            }
                          }
                        },
                        "editorId": "iconbutton8"
                      }
                    ],
                    "editorId": "row51"
                  },
                  {
                    "type": "container",
                    "properties": {
                      "width": {
                        "px": {
                          "value": 120,
                          "isInfinity": false
                        }
                      },
                      "height": {
                        "px": {
                          "value": 120,
                          "isInfinity": false
                        }
                      },
                      "radius": {
                        "radius": {
                          "topLeft": 0,
                          "topRight": 0,
                          "bottomLeft": 0,
                          "bottomRight": 0,
                          "token": "full"
                        }
                      },
                      "bg": {
                        "color": {
                          "color": "on_primary",
                          "opacityPercent": 20
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "token": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "lottie",
                        "properties": {
                          "source_desc": {
                            "imageSource": {
                              "type": "IMAGE_SOURCE_TYPE_URL",
                              "value": "https://dimg.dreamflow.cloud/v1/image/celebration+animation"
                            }
                          },
                          "fit": {
                            "stringVal": {
                              "value": "contain"
                            }
                          }
                        },
                        "editorId": "lottie3"
                      }
                    ],
                    "editorId": "container76"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      },
                      "align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Oobli Wrapped"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_medium"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_surface"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 900
                            }
                          }
                        },
                        "editorId": "text87"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "NOVEMBER 2023"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_surface",
                              "opacityPercent": 80
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text88"
                      }
                    ],
                    "editorId": "column68"
                  }
                ],
                "editorId": "column67"
              }
            ],
            "editorId": "container75"
          },
          {
            "type": "column",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "spacing": {
                "stringVal": {
                  "value": "xl"
                }
              },
              "cross_align": {
                "align": {
                  "named": "stretch"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "You handled"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "body_medium"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      }
                    },
                    "editorId": "text89"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "KES 84,250"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "headline_large"
                        }
                      },
                      "font_weight": {
                        "numberVal": {
                          "value": 900
                        }
                      },
                      "color": {
                        "color": {
                          "color": "primary_text"
                        }
                      }
                    },
                    "editorId": "text90"
                  },
                  {
                    "type": "wrap",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "sm"
                        }
                      },
                      "run_spacing": {
                        "stringVal": {
                          "value": "sm"
                        }
                      },
                      "align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@insight_pill",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "Saver"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "leaf_saved_rounded"
                            }
                          },
                          "bg_color": {
                            "stringVal": {
                              "value": "success/20"
                            }
                          }
                        },
                        "editorId": "insightpill1"
                      },
                      {
                        "type": "@insight_pill",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "M-Pesa Power User"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "bolt_rounded"
                            }
                          },
                          "bg_color": {
                            "stringVal": {
                              "value": "warning/20"
                            }
                          }
                        },
                        "editorId": "insightpill2"
                      }
                    ],
                    "editorId": "wrap1"
                  }
                ],
                "editorId": "column70"
              },
              {
                "type": "container",
                "properties": {
                  "bg": {
                    "color": {
                      "color": "surface_variant"
                    }
                  },
                  "radius": {
                    "radius": {
                      "topLeft": 0,
                      "topRight": 0,
                      "bottomLeft": 0,
                      "bottomRight": 0,
                      "token": "lg"
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "border": {
                    "border": {
                      "width": 1,
                      "color": "outline"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "start"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "container",
                        "properties": {
                          "width": {
                            "px": {
                              "value": 48,
                              "isInfinity": false
                            }
                          },
                          "height": {
                            "px": {
                              "value": 48,
                              "isInfinity": false
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 12,
                              "topRight": 12,
                              "bottomLeft": 12,
                              "bottomRight": 12
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "primary"
                            }
                          },
                          "align_child": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "psychology_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "on_surface"
                                }
                              },
                              "size": {
                                "numberVal": {
                                  "value": 28
                                }
                              }
                            },
                            "editorId": "icon26"
                          }
                        ],
                        "editorId": "container78"
                      },
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "sm"
                            }
                          },
                          "expanded": {
                            "expanded": {
                              "enabled": true,
                              "flex": 1
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Oobli says..."
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "title_medium"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary_text"
                                }
                              }
                            },
                            "editorId": "text91"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Your spending on 'Pochi la Biashara' peaked on Fridays. Most of these were grocery runs that AI re-categorized for you!"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "body_medium"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "secondary_text"
                                }
                              }
                            },
                            "editorId": "text92"
                          }
                        ],
                        "editorId": "column71"
                      }
                    ],
                    "editorId": "row52"
                  }
                ],
                "editorId": "container77"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Where it went"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "title_large"
                        }
                      },
                      "font_weight": {
                        "stringVal": {
                          "value": "bold"
                        }
                      }
                    },
                    "editorId": "text93"
                  },
                  {
                    "type": "@category_rank",
                    "properties": {
                      "rank": {
                        "numberVal": {
                          "value": 1
                        }
                      },
                      "category": {
                        "stringVal": {
                          "value": "Food & Dining"
                        }
                      },
                      "amount": {
                        "stringVal": {
                          "value": "KES 32,000"
                        }
                      },
                      "color": {
                        "stringVal": {
                          "value": "primary"
                        }
                      }
                    },
                    "editorId": "categoryrank1"
                  },
                  {
                    "type": "@category_rank",
                    "properties": {
                      "rank": {
                        "numberVal": {
                          "value": 2
                        }
                      },
                      "category": {
                        "stringVal": {
                          "value": "Transport"
                        }
                      },
                      "amount": {
                        "stringVal": {
                          "value": "KES 12,500"
                        }
                      },
                      "color": {
                        "stringVal": {
                          "value": "accent"
                        }
                      }
                    },
                    "editorId": "categoryrank2"
                  },
                  {
                    "type": "@category_rank",
                    "properties": {
                      "rank": {
                        "numberVal": {
                          "value": 3
                        }
                      },
                      "category": {
                        "stringVal": {
                          "value": "Utilities"
                        }
                      },
                      "amount": {
                        "stringVal": {
                          "value": "KES 8,400"
                        }
                      },
                      "color": {
                        "stringVal": {
                          "value": "success"
                        }
                      }
                    },
                    "editorId": "categoryrank3"
                  }
                ],
                "editorId": "column72"
              },
              {
                "type": "container",
                "properties": {
                  "bg": {
                    "color": {
                      "color": "surface"
                    }
                  },
                  "radius": {
                    "radius": {
                      "topLeft": 0,
                      "topRight": 0,
                      "bottomLeft": 0,
                      "bottomRight": 0,
                      "token": "lg"
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "border": {
                    "border": {
                      "width": 1,
                      "color": "divider"
                    }
                  }
                },
                "children": [
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Spending Flow"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "title_medium"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "text94"
                      },
                      {
                        "type": "container",
                        "properties": {
                          "height": {
                            "px": {
                              "value": 200,
                              "isInfinity": false
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "@std.pie_chart",
                            "properties": {
                              "variant": {
                                "stringVal": {
                                  "value": "donut"
                                }
                              },
                              "data": {
                                "stringVal": {
                                  "value": "32,12,8,48"
                                }
                              },
                              "labels": {
                                "stringVal": {
                                  "value": "Food,Transport,Bills,Other"
                                }
                              },
                              "colors": {
                                "stringVal": {
                                  "value": "primary,accent,success,divider"
                                }
                              },
                              "ring": {
                                "stringVal": {
                                  "value": "thick"
                                }
                              },
                              "legend": {
                                "stringVal": {
                                  "value": "bottom"
                                }
                              },
                              "legend_value": {
                                "stringVal": {
                                  "value": "percent"
                                }
                              }
                            },
                            "editorId": "stdpiechart3"
                          }
                        ],
                        "editorId": "container80"
                      }
                    ],
                    "editorId": "column73"
                  }
                ],
                "editorId": "container79"
              },
              {
                "type": "container",
                "properties": {
                  "bg": {
                    "color": {
                      "color": "success",
                      "opacityPercent": 10
                    }
                  },
                  "radius": {
                    "radius": {
                      "topLeft": 0,
                      "topRight": 0,
                      "bottomLeft": 0,
                      "bottomRight": 0,
                      "token": "lg"
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  },
                  "border": {
                    "border": {
                      "width": 1,
                      "color": "success/30"
                    }
                  }
                },
                "children": [
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "cross_align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "icon",
                        "properties": {
                          "name": {
                            "icon": {
                              "name": "workspace_premium_rounded"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_surface"
                            }
                          },
                          "size": {
                            "numberVal": {
                              "value": 32
                            }
                          }
                        },
                        "editorId": "icon27"
                      },
                      {
                        "type": "column",
                        "properties": {
                          "spacing": {
                            "stringVal": {
                              "value": "xs"
                            }
                          },
                          "expanded": {
                            "expanded": {
                              "enabled": true,
                              "flex": 1
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "Financial Win!"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "title_small"
                                }
                              },
                              "font_weight": {
                                "stringVal": {
                                  "value": "bold"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "on_surface"
                                }
                              }
                            },
                            "editorId": "text95"
                          },
                          {
                            "type": "text",
                            "properties": {
                              "content": {
                                "stringVal": {
                                  "value": "You spent 15% less on dining out compared to October. Oobli is proud!"
                                }
                              },
                              "style": {
                                "textStyle": {
                                  "styleName": "body_small"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "primary_text"
                                }
                              }
                            },
                            "editorId": "text96"
                          }
                        ],
                        "editorId": "column74"
                      }
                    ],
                    "editorId": "row53"
                  }
                ],
                "editorId": "container81"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "bottomToken": "lg"
                    }
                  }
                },
                "children": [
                  {
                    "type": "@std.button",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "View Full Breakdown"
                        }
                      },
                      "variant": {
                        "stringVal": {
                          "value": "outline"
                        }
                      },
                      "full_width": {
                        "boolVal": {
                          "value": true
                        }
                      }
                    },
                    "editorId": "stdbutton18"
                  },
                  {
                    "type": "@std.button",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Update December Plan"
                        }
                      },
                      "variant": {
                        "stringVal": {
                          "value": "primary"
                        }
                      },
                      "full_width": {
                        "boolVal": {
                          "value": true
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "arrow_forward_rounded"
                        }
                      }
                    },
                    "editorId": "stdbutton19"
                  }
                ],
                "editorId": "column75"
              }
            ],
            "editorId": "column69"
          }
        ],
        "editorId": "column66"
      }
    ],
    "editorId": "scaffold9"
  }
}
```

### 10. Settings & Profile

- Frame ID: `frame7`
- Original page prompt: "User profile and app configuration settings"
- Follow-up prompts: _None_

#### DslDocument (JSON)

```json
{
  "root": {
    "type": "scaffold",
    "properties": {
      "bg": {
        "color": {
          "color": "background"
        }
      }
    },
    "children": [
      {
        "type": "column",
        "properties": {
          "scroll": {
            "boolVal": {
              "value": true
            }
          },
          "cross_align": {
            "align": {
              "named": "stretch"
            }
          }
        },
        "children": [
          {
            "type": "container",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 32,
                  "right": 24,
                  "bottom": 24,
                  "left": 24
                }
              },
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "radius": {
                "radius": {
                  "topLeft": 0,
                  "topRight": 0,
                  "bottomLeft": 32,
                  "bottomRight": 32
                }
              },
              "shadow": {
                "stringVal": {
                  "value": "sm"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "md"
                    }
                  },
                  "align": {
                    "align": {
                      "named": "center"
                    }
                  }
                },
                "children": [
                  {
                    "type": "stack",
                    "properties": {
                      "align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "avatar",
                        "properties": {
                          "text": {
                            "stringVal": {
                              "value": "JW"
                            }
                          },
                          "size": {
                            "numberVal": {
                              "value": 80
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "primary"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_primary"
                            }
                          },
                          "font_size": {
                            "numberVal": {
                              "value": 28
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          }
                        },
                        "editorId": "avatar3"
                      },
                      {
                        "type": "container",
                        "properties": {
                          "align": {
                            "align": {
                              "positional": {
                                "x": 1,
                                "y": 1
                              }
                            }
                          },
                          "width": {
                            "px": {
                              "value": 28,
                              "isInfinity": false
                            }
                          },
                          "height": {
                            "px": {
                              "value": 28,
                              "isInfinity": false
                            }
                          },
                          "bg": {
                            "color": {
                              "color": "success"
                            }
                          },
                          "radius": {
                            "radius": {
                              "topLeft": 0,
                              "topRight": 0,
                              "bottomLeft": 0,
                              "bottomRight": 0,
                              "token": "full"
                            }
                          },
                          "border": {
                            "border": {
                              "width": 3,
                              "color": "surface"
                            }
                          },
                          "align_child": {
                            "align": {
                              "named": "center"
                            }
                          }
                        },
                        "children": [
                          {
                            "type": "icon",
                            "properties": {
                              "name": {
                                "icon": {
                                  "name": "check_rounded"
                                }
                              },
                              "color": {
                                "color": {
                                  "color": "on_surface"
                                }
                              },
                              "size": {
                                "numberVal": {
                                  "value": 16
                                }
                              }
                            },
                            "editorId": "icon28"
                          }
                        ],
                        "editorId": "container83"
                      }
                    ],
                    "editorId": "stack3"
                  },
                  {
                    "type": "column",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "xs"
                        }
                      },
                      "align": {
                        "align": {
                          "named": "center"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Jared Waweru"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "headline_small"
                            }
                          },
                          "font_weight": {
                            "stringVal": {
                              "value": "bold"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "primary_text"
                            }
                          }
                        },
                        "editorId": "text97"
                      },
                      {
                        "type": "text",
                        "properties": {
                          "content": {
                            "stringVal": {
                              "value": "Oobli Pro Member"
                            }
                          },
                          "style": {
                            "textStyle": {
                              "styleName": "label_large"
                            }
                          },
                          "color": {
                            "color": {
                              "color": "on_surface"
                            }
                          },
                          "font_weight": {
                            "numberVal": {
                              "value": 600
                            }
                          }
                        },
                        "editorId": "text98"
                      }
                    ],
                    "editorId": "column78"
                  },
                  {
                    "type": "row",
                    "properties": {
                      "spacing": {
                        "stringVal": {
                          "value": "md"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 0,
                          "bottom": 0,
                          "left": 0,
                          "topToken": "top",
                          "rightToken": "md",
                          "bottomToken": "top",
                          "leftToken": "md"
                        }
                      }
                    },
                    "children": [
                      {
                        "type": "@profile_stat",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "Streak"
                            }
                          },
                          "value": {
                            "stringVal": {
                              "value": "12 Days"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "fire_hydrant_rounded"
                            }
                          }
                        },
                        "editorId": "profilestat1"
                      },
                      {
                        "type": "@profile_stat",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "Saved"
                            }
                          },
                          "value": {
                            "stringVal": {
                              "value": "KES 4.2k"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "account_balance_wallet_rounded"
                            }
                          }
                        },
                        "editorId": "profilestat2"
                      },
                      {
                        "type": "@profile_stat",
                        "properties": {
                          "label": {
                            "stringVal": {
                              "value": "Accuracy"
                            }
                          },
                          "value": {
                            "stringVal": {
                              "value": "94%"
                            }
                          },
                          "icon": {
                            "stringVal": {
                              "value": "auto_awesome_rounded"
                            }
                          }
                        },
                        "editorId": "profilestat3"
                      }
                    ],
                    "editorId": "row54"
                  }
                ],
                "editorId": "column77"
              }
            ],
            "editorId": "container82"
          },
          {
            "type": "column",
            "properties": {
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "lg"
                }
              },
              "spacing": {
                "stringVal": {
                  "value": "lg"
                }
              },
              "cross_align": {
                "align": {
                  "named": "stretch"
                }
              }
            },
            "children": [
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "sm"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "start"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Financial Engine"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_large"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "font_weight": {
                        "stringVal": {
                          "value": "bold"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 4,
                          "bottom": 0,
                          "left": 4
                        }
                      }
                    },
                    "editorId": "text99"
                  },
                  {
                    "type": "@setting_row",
                    "properties": {
                      "icon": {
                        "stringVal": {
                          "value": "message_rounded"
                        }
                      },
                      "title": {
                        "stringVal": {
                          "value": "SMS Syncing"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "Managing M-Pesa & Bank alerts"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "primary"
                        }
                      }
                    },
                    "editorId": "settingrow1"
                  },
                  {
                    "type": "@setting_row",
                    "properties": {
                      "icon": {
                        "stringVal": {
                          "value": "smart_toy_rounded"
                        }
                      },
                      "title": {
                        "stringVal": {
                          "value": "Oobli AI Brain"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "Categorization: Optimized"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "accent"
                        }
                      }
                    },
                    "editorId": "settingrow2"
                  },
                  {
                    "type": "@setting_row",
                    "properties": {
                      "icon": {
                        "stringVal": {
                          "value": "security_rounded"
                        }
                      },
                      "title": {
                        "stringVal": {
                          "value": "Privacy & Security"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "Biometric lock enabled"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "success"
                        }
                      }
                    },
                    "editorId": "settingrow3"
                  }
                ],
                "editorId": "column80"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "sm"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "start"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Experience"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_large"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "font_weight": {
                        "stringVal": {
                          "value": "bold"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 4,
                          "bottom": 0,
                          "left": 4
                        }
                      }
                    },
                    "editorId": "text100"
                  },
                  {
                    "type": "@setting_row",
                    "properties": {
                      "icon": {
                        "stringVal": {
                          "value": "notifications_active_rounded"
                        }
                      },
                      "title": {
                        "stringVal": {
                          "value": "Oobli Insights"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "Daily spending nudges"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "warning"
                        }
                      }
                    },
                    "editorId": "settingrow4"
                  },
                  {
                    "type": "@setting_row",
                    "properties": {
                      "icon": {
                        "stringVal": {
                          "value": "palette_rounded"
                        }
                      },
                      "title": {
                        "stringVal": {
                          "value": "App Theme"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "Minimalist Light"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "secondary"
                        }
                      }
                    },
                    "editorId": "settingrow5"
                  },
                  {
                    "type": "@setting_row",
                    "properties": {
                      "icon": {
                        "stringVal": {
                          "value": "celebrate_rounded"
                        }
                      },
                      "title": {
                        "stringVal": {
                          "value": "Oobli Wrapped"
                        }
                      },
                      "subtitle": {
                        "stringVal": {
                          "value": "Monthly recap settings"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "info"
                        }
                      }
                    },
                    "editorId": "settingrow6"
                  }
                ],
                "editorId": "column81"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "sm"
                    }
                  },
                  "cross_align": {
                    "align": {
                      "named": "start"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Support"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_large"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "secondary_text"
                        }
                      },
                      "font_weight": {
                        "stringVal": {
                          "value": "bold"
                        }
                      },
                      "padding": {
                        "edgeInsets": {
                          "top": 0,
                          "right": 4,
                          "bottom": 0,
                          "left": 4
                        }
                      }
                    },
                    "editorId": "text101"
                  },
                  {
                    "type": "@setting_row",
                    "properties": {
                      "icon": {
                        "stringVal": {
                          "value": "help_outline_rounded"
                        }
                      },
                      "title": {
                        "stringVal": {
                          "value": "Help Center"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "secondary_text"
                        }
                      }
                    },
                    "editorId": "settingrow7"
                  },
                  {
                    "type": "@setting_row",
                    "properties": {
                      "icon": {
                        "stringVal": {
                          "value": "logout_rounded"
                        }
                      },
                      "title": {
                        "stringVal": {
                          "value": "Sign Out"
                        }
                      },
                      "tone": {
                        "stringVal": {
                          "value": "error"
                        }
                      },
                      "show_chevron": {
                        "boolVal": {
                          "value": false
                        }
                      }
                    },
                    "editorId": "settingrow8"
                  }
                ],
                "editorId": "column82"
              },
              {
                "type": "column",
                "properties": {
                  "spacing": {
                    "stringVal": {
                      "value": "xs"
                    }
                  },
                  "align": {
                    "align": {
                      "named": "center"
                    }
                  },
                  "padding": {
                    "edgeInsets": {
                      "top": 0,
                      "right": 0,
                      "bottom": 0,
                      "left": 0,
                      "token": "lg"
                    }
                  }
                },
                "children": [
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Oobli v2.4.0"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "on_background"
                        }
                      }
                    },
                    "editorId": "text102"
                  },
                  {
                    "type": "text",
                    "properties": {
                      "content": {
                        "stringVal": {
                          "value": "Made with ❤️ in Nairobi"
                        }
                      },
                      "style": {
                        "textStyle": {
                          "styleName": "label_small"
                        }
                      },
                      "color": {
                        "color": {
                          "color": "on_background"
                        }
                      }
                    },
                    "editorId": "text103"
                  }
                ],
                "editorId": "column83"
              }
            ],
            "editorId": "column79"
          },
          {
            "type": "container",
            "properties": {
              "align": {
                "align": {
                  "named": "bottom"
                }
              },
              "bg": {
                "color": {
                  "color": "surface"
                }
              },
              "border": {
                "borderSided": {
                  "side": "top",
                  "width": 1,
                  "color": "divider"
                }
              },
              "padding": {
                "edgeInsets": {
                  "top": 0,
                  "right": 0,
                  "bottom": 0,
                  "left": 0,
                  "token": "md"
                }
              }
            },
            "children": [
              {
                "type": "@std.bottom_nav",
                "children": [
                  {
                    "type": "@std.nav_item",
                    "properties": {
                      "target": {
                        "stringVal": {
                          "value": "home"
                        }
                      },
                      "label": {
                        "stringVal": {
                          "value": "Feed"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "dashboard_rounded"
                        }
                      }
                    },
                    "editorId": "stdnavitem13"
                  },
                  {
                    "type": "@std.nav_item",
                    "properties": {
                      "target": {
                        "stringVal": {
                          "value": "planning"
                        }
                      },
                      "label": {
                        "stringVal": {
                          "value": "Plans"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "edit_note_rounded"
                        }
                      }
                    },
                    "editorId": "stdnavitem14"
                  },
                  {
                    "type": "@std.nav_item",
                    "properties": {
                      "target": {
                        "stringVal": {
                          "value": "goals"
                        }
                      },
                      "label": {
                        "stringVal": {
                          "value": "Goals"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "track_changes_rounded"
                        }
                      }
                    },
                    "editorId": "stdnavitem15"
                  },
                  {
                    "type": "@std.nav_item",
                    "properties": {
                      "target": {
                        "stringVal": {
                          "value": "profile"
                        }
                      },
                      "label": {
                        "stringVal": {
                          "value": "Profile"
                        }
                      },
                      "icon": {
                        "stringVal": {
                          "value": "person_rounded"
                        }
                      },
                      "selected": {
                        "boolVal": {
                          "value": true
                        }
                      }
                    },
                    "editorId": "stdnavitem16"
                  }
                ],
                "editorId": "stdbottomnav4"
              }
            ],
            "editorId": "container84"
          }
        ],
        "editorId": "column76"
      }
    ],
    "editorId": "scaffold10"
  }
}
```