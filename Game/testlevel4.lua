return {
  version = "1.1",
  luaversion = "5.1",
  orientation = "orthogonal",
  width = 20,
  height = 12,
  tilewidth = 16,
  tileheight = 16,
  properties = {},
  tilesets = {
    {
      name = "Dirt",
      firstgid = 1,
      tilewidth = 16,
      tileheight = 16,
      spacing = 0,
      margin = 0,
      image = "Dirt.png",
      imagewidth = 80,
      imageheight = 160,
      transparentcolor = "#ff00ff",
      properties = {},
      tiles = {
        {
          id = 5,
          properties = {
            ["collision"] = "15"
          }
        },
        {
          id = 8,
          properties = {
            ["collision"] = "15"
          }
        },
        {
          id = 21,
          properties = {
            ["collision"] = "15"
          }
        },
        {
          id = 22,
          properties = {
            ["collision"] = "15"
          }
        },
        {
          id = 33,
          properties = {
            ["collision"] = "15"
          }
        },
        {
          id = 34,
          properties = {
            ["collision"] = "15"
          }
        },
        {
          id = 35,
          properties = {
            ["collision"] = "15"
          }
        },
        {
          id = 37,
          properties = {
            ["collision"] = "15"
          }
        },
        {
          id = 38,
          properties = {
            ["collision"] = "15"
          }
        },
        {
          id = 39,
          properties = {
            ["collision"] = "15"
          }
        }
      }
    },
    {
      name = "testlevel_obj",
      firstgid = 51,
      tilewidth = 16,
      tileheight = 16,
      spacing = 0,
      margin = 0,
      image = "testlevel_obj.png",
      imagewidth = 128,
      imageheight = 128,
      transparentcolor = "#ff00ff",
      properties = {},
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "Calque de Tile 1",
      x = 0,
      y = 0,
      width = 20,
      height = 12,
      visible = true,
      opacity = 1,
      properties = {},
      encoding = "lua",
      data = {
        8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
        8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8,
        42, 13, 42, 42, 42, 42, 42, 42, 42, 11, 42, 42, 42, 11, 42, 14, 42, 42, 42, 12,
        42, 12, 42, 42, 42, 42, 42, 42, 42, 14, 42, 42, 42, 13, 42, 12, 42, 42, 42, 14,
        42, 11, 42, 42, 42, 42, 42, 42, 42, 12, 42, 42, 42, 14, 42, 11, 42, 42, 42, 14,
        6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 22, 41, 23, 9,
        1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 34, 20, 35, 2,
        3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 34, 41, 35, 4,
        38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 36, 20, 39, 38,
        41, 20, 41, 20, 41, 20, 41, 20, 41, 20, 41, 20, 41, 20, 41, 20, 41, 20, 41, 20,
        20, 41, 20, 41, 20, 41, 41, 41, 20, 41, 20, 41, 20, 41, 20, 41, 20, 41, 20, 41,
        40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40, 40
      }
    },
    {
      type = "tilelayer",
      name = "Object",
      x = 0,
      y = 0,
      width = 20,
      height = 12,
      visible = true,
      opacity = 1,
      properties = {},
      encoding = "lua",
      data = {
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
      }
    },
    {
      type = "objectgroup",
      name = "Object Layer 1",
      visible = true,
      opacity = 1,
      properties = {},
      objects = {
        {
          name = "",
          type = "Player",
          shape = "rectangle",
          x = 32,
          y = 41,
          width = 14,
          height = 12,
          visible = true,
          properties = {}
        }
      }
    }
  }
}
