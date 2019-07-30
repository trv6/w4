return require('config').load({
    unit_height = 25,
    palette_region = {
        button_width = 30,
        backdrop = {
            visible = true,
            color = {a = 133, r = 0, g = 0, b = 0},
        },
        button = {
            text = {
                bold = true,
                italic = false,
                font = "Times",
                size = 15,
                color = {a = 255, r = 255, g = 255, b = 255},
                visible = true,
            },
            color = {a = 200, r = 0, g = 0, b = 0},
            background_visibility = false,
            image_visibility = false,
        },
        highlight = {
            color = {a = 100, r = 255, g = 255, b = 255},
            visible = true,
        },
    },
    target_region = {
        create_target_display = true,
        height = 30,
        width = 150,
        text = {
            name = {
                bold = true,
                font = "Consolas",
                font_size = 10,
                truncate = 10,
                offset = {x = -150, y = -3},
                right_justified = false,
            },
            hpp = {
                bold = true,
                font = "Consolas",
                font_size = 10,
                offset = {x = -150, y = 11},
                visible = true,
                right_justified = false
            },
        },
    },
    status_effect_region = {
        display_party_status_effects = true,
        display_p0_status_effects = true,
    },
    stat_region = {
        text = {
            name = {
                bold = true,
                font = "Consolas",
                font_size = 10,
                truncate = 10,
                offset = {x = -150, y = -2},
                visible = true,
                right_justified = false,
                out_of_range_color = {a = 255, r = 175, g = 98, b = 177},
            },
            tp = {
                bold = true,
                font = "Consolas",
                font_size = 10,
                offset = {x = -150, y = 11},
                visible = true,
                right_justified = false
            },
            hp = {
                bold = true,
                font = "Consolas",
                font_size = 10,
                offset = {x = -42, y = -2},
                visible = true,
                right_justified = true
            },
            mp = {
                bold = true,
                font = "Consolas",
                font_size = 10,
                offset = {x = -42, y = 11},
                visible = true,
                right_justified = true
            },
            zone = {
                bold = true,
                font = "Consolas",
                font_size = 10,
                italic = true,
                color = {a = 120, r = 255, g = 255, b = 255},
                offset = {x = -150, y = 10},
                visible = true,
                right_justified = false
            },
            hpp = {
                bold = true,
                font = "Times",
                font_size = 20,
                offset = {x = 0, y = -2},
                visible = true,
                right_justified = true
            },
        },
        prim = {
            width = 150,
            bg = {
                visible = true,
                color = {a = 200, r = 0, g = 0, b = 0},
            },
            hp_bar_percentage_colors = {
                --a = 176, -- uncomment for a bug in the config library
                [100] = {a = 176, r = 1, g = 100, b = 14},
                [75] = {a = 176, r = 255, g = 255, b = 0},
                [50] = {a = 176, r = 255, g = 100, b = 1},
                [25] = {a = 176, r = 255, g = 0, b = 0},
            },
            mp_bar = {
                color = {a = 100, r = 149, g = 212, b = 255},
                height = 5,
            },
        },
    },
    location = {
        y_offset_pt1 = 0,
        y_offset_pt2 = 25 * 13 + 10,
        y_offset_pt3 = 25 * 19 + 20,
        x_offset = 0,
        y_offset = 0,
    },
})

