from numpy import fromfunction, zeros

class Engine:
	def __init__(self, x, y, z, temp, k=0.05, spacing = 0.1):
		self.calcspace = fromfunction(temp, (x,y,z), dtype=float)
		self.prev = self.calcspace.copy()
		self.objects = zeros((x,y,z), dtype=int)
		self.nextObj = 1
		self.startTemp = temp(0,0,0)
		self.kVals = [[k]]
		self.spacing = spacing
		

	def insertObject(self, x, y, z, xsize, ysize, zsize, temp, k = 0.3):
		for i in xrange(x, x+xsize):
			for j in xrange(y, y+ysize):
				for k in xrange(z, z+zsize):
					self.calcspace[i][j][k] = temp(i, j, k)
					self.objects[i][j][k] = self.nextObj
		self.nextObj += 1
		self.kVals.append([k, x, y, z, xsize, ysize, zsize])
		return len(self.kVals) - 1

	def moveObject(self, obj, xd, yd, zd, trace = False):
		x = self.kVals[obj][1]
		y = self.kVals[obj][2]
		z = self.kVals[obj][3]
		xs = self.kVals[obj][4]
		ys = self.kVals[obj][5]
		zs = self.kVals[obj][5]
		if x+xd < 0 or x+xs+xd > len(self.calcspace) or y+yd < 0 or y+ys+yd > len(self.calcspace[0]) or z+zd < 0 or z+zs+zd > len(self.calcspace[0][0]):
			if trace:
				print "Invalid move. Out of bounds!"
			return

		for i in xrange(x, x+xs):
			for j in xrange(y, y+ys):
				for k in xrange(z, z+zs):
					if self.objects[i+xd][j+yd][k+zd] != 0 and self.objects[i+xd][j+yd][k+zd] != obj:
						if trace:
							print "Invalid move. Object %d is in the way" % (self.objects[i+xd][j+yd][k+zd])
						return
		dupCalc = self.calcspace.copy()
		for i in xrange(x, x+xs):
			for j in xrange(y, y+ys):
				for k in xrange(z, z+zs):
					self.calcspace[xd+i][yd+j][zd+k] = dupCalc[i][j][k]

	def iterate(self, dt):
		pre = dt/self.spacing**2
		ys = len(self.calcspace[0])
		zs = len(self.calcspace[0][0])
		obj = self.objects
		kV = self.kVals
		prev = self.prev
		calcSp = self.calcspace

		print pre
		print 0.51*dt*dt
		for x in xrange(1, len(calcSp)-1):
			for y in xrange(1, ys-1):
				for z in xrange(1, zs-1):
					calc = -6*calcSp[x][y][z]*kV[obj[x][y][z]][0]\
					+ calcSp[x+1][y][z]*kV[obj[x+1][y][z]][0]\
					+ calcSp[x-1][y][z]*kV[obj[x-1][y][z]][0]\
					+ calcSp[x][y+1][z]*kV[obj[x][y+1][z]][0]\
					+ calcSp[x][y-1][z]*kV[obj[x][y-1][z]][0]\
					+ calcSp[x][y][z+1]*kV[obj[x][y][z+1]][0]\
					+ calcSp[x][y][z-1]*kV[obj[x][y][z-1]][0]
					prev[x][y][z] = calcSp[x][y][z] + pre * calc
					print "n %f %f" % (calcSp[x][y][z], calc*pre)
		tmp = self.calcspace
		self.calcspace = self.prev
		self.prev = tmp
		print self.calcspace
					

if __name__ == '__main__':
	eng = Engine(5,5,5,lambda i, j, k: i*0+3, 0.05, 0.5)
	eng.insertObject(1, 1, 1, 3, 3, 3, lambda i, j, k: i*0+10)
	#eng.moveObject(1,5,5,5, True)
	eng.iterate(0.0001)
