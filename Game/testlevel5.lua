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
          id = 6,
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
        42, 13, 42, 42, 42, 42, 42, 11, 42, 14, 42, 42, 42, 42, 42, 42, 42, 42, 12, 42,
        42, 11, 42, 42, 42, 42, 42, 12, 42, 13, 42, 42, 42, 42, 42, 42, 42, 42, 11, 42,
        42, 14, 42, 42, 42, 42, 42, 14, 42, 11, 42, 42, 42, 42, 42, 42, 42, 42, 14, 42,
        6, 7, 6, 7, 6, 7, 6, 7, 6, 7, 6, 7, 6, 6, 6, 7, 6, 7, 6, 7,
        1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2, 1, 2,
        3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4, 3, 4,
        38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38, 38,
        9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10,
        10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9, 10, 9,
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
      name = "Calque d'objets 1",
      visible = true,
      opacity = 1,
      properties = {},
      objects = {
        {
          name = "",
          type = "Player",
          shape = "rectangle",
          x = 19,
          y = 151,
          width = 17,
          height = 17,
          visible = true,
          properties = {}
        }
      }
    }
  }
}
