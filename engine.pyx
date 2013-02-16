from numpy import fromfunction, zeros

class Engine:
	def __init__(self, x, y, temp, k=0.05):
		self.calcspace = fromfunction(temp, (x,y), dtype=float)
		self.objects = zeros((x,y))
		self.nextObj = 1
		self.startTemp = temp(0,0)
		self.kVals = [k]

	def insertObject(self, x, y, xsize, ysize, temp, k = 0.3):
		for i in xrange(x, x+xsize):
			for j in xrange(y, y+ysize):
				self.calcspace[i][j] = temp(i, j)
				self.objects[i][j] = self.nextObj
		self.nextObj += 1
		self.kVals.append([k, x, y, xsize, ysize])
		return len(self.kVals) - 1

	def moveObject(self, obj, xd, yd, trace = False):
		dupCalc = self.calcspace.copy()
		x = self.kVals[obj][1]
		y = self.kVals[obj][2]
		xs = self.kVals[obj][3]
		ys = self.kVals[obj][4]
		if x+xd < 0 or x+xs+xd > len(self.calcspace) or y+yd < 0 or y+ys+yd > len(self.calcspace[0]):
			if trace:
				print "Invalid move. Out of bounds!"
			return

		for i in xrange(x, x+xs):
			for j in xrange(y, y+ys):
				if self.objects[i+xd][j+yd] != 0 and self.objects[i+xd][j+yd] != obj:
					if trace:
						print "Invalid move. Object %d is in the way" % (self.objects[i+xd][j+yd])
		for i in xrange(x, x+xs):
			for j in xrange(y, y+ys):
				self.calcspace[xd+i][yd+j] = dupCalc[i][j]

	def iterate(self, dt):
		pass

if __name__ == '__main__':
	eng = Engine(100,100,lambda i, j: i*0+3)
	eng.insertObject(0, 0, 3, 3, lambda i, j: i*0+10)
	eng.moveObject(1,5,5, True)
	eng.iterate(0.1)
