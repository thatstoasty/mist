def hex_to_rgb(hexa):
    result = []
    for i in (0, 2, 4):
        result.append(int(hexa[i : i + 2], 16))
    return result


print(hex_to_rgb("ff0000"))
