from PIL import Image

colorfile = "C1W"
heightfile = "D1"

skycolor = "\t\t0: color = skycolor;\n"

mifcolors = []
mifheights = []

with Image.open("maps/" + colorfile + ".png") as colormap:
	colorsmall = colormap.resize((256,256), resample = Image.LANCZOS).quantize(colors=15, method=Image.MEDIANCUT) # change to MAXCOVERAGE/MEDIANCUT and compare
	with open("generated/" + colorfile + "_palette.txt", mode="w") as palettefile:
		pal = colorsmall.getpalette()[:45]
		palettefile.write(skycolor)
		for i in range(1,16):
			curcolor = tuple(pal[(i-1)*3:i*3])
			colorhex = "".join(hex(int(round((c*15)/255)))[2] for c in curcolor).upper()
			palettefile.write("\t\t"+str(i)+": color = 12'h" + colorhex + ";\n")
	for x in range(256):
		for y in range(256):
			mifcolors.append(colorsmall.getpixel((x,y))+1) # palette index

with Image.open("maps/"+heightfile+".png") as heightmap:
	heightsmall = heightmap.resize((256,256), resample = Image.LANCZOS)
	for x in range(256):
		for y in range(256):
			mifheights.append(int(round(heightsmall.getpixel((x,y))/4))) # palette index
	while max(mifheights)>31:
		mifheights = [h//2 for h in mifheights] # if map too high, scale to half
		print("scaling map heights down by 2, map will appear flatter")

with open("generated/" + colorfile+".mif", mode="w") as outfile:
	outfile.write("Width=9;\nDEPTH=65536;\nADDRESS_RADIX=HEX;\nDATA_RADIX=HEX;\nCONTENT BEGIN\n")
	for y in range(256):
		for x in range(256):
			addr = hex(y*256+x)[2:].upper()
			outfile.write("\t"+addr+" : "+hex(mifheights[(x*256)+y]*16 + mifcolors[(x*256)+y])[2:].upper()+";\n")
	outfile.write("END;")

colorsmall.resize((1024, 1024), resample = Image.NEAREST).save("generated/"+colorfile+"_quantized.png")