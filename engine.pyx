from numpy import fromfunction, zeros
import pygame
from pygame.locals import *
from OpenGL.GL import *
from OpenGL.GLU import *

class Engine:
	def __init__(self, x, y, z, temp, k=0.05, spacing = 0.1):
		self.calcspace = fromfunction(temp, (x,y,z), dtype=float)
		self.prev = self.calcspace.copy()
		self.objects = zeros((x,y,z), dtype=int)
		self.nextObj = 1
		self.startTemp = temp(0,0,0)
		self.kVals = [[k]]
		self.spacing = spacing
		

	def insertObject(self, x, y, z, xsize, ysize, zsize, temp, kv = 0.3):
		for i in xrange(x, x+xsize):
			for j in xrange(y, y+ysize):
				for k in xrange(z, z+zsize):
					self.calcspace[i][j][k] = temp(i, j, k)
					self.objects[i][j][k] = self.nextObj
		self.nextObj += 1
		self.kVals.append([kv, x, y, z, xsize, ysize, zsize])
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
		print calcSp

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
					print "n %f %f %f" % (calcSp[x][y][z], calc*pre, kV[obj[x][y][z]][0])
		tmp = self.calcspace
		self.calcspace = self.prev
		self.prev = tmp
		print self.calcspace
	def initRender(self, size):
		pygame.init()
		screen = pygame.display.set_mode(size, HWSURFACE | OPENGL | DOUBLEBUF)
		glViewport(0, 0, size[0], size[1])
		glShadeModel(GL_SMOOTH)
		glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST)
		viewport = glGetIntegerv( GL_VIEWPORT )
		glMatrixMode(GL_PROJECTION)
		glLoadIdentity()
		gluPerspective(60.0, float(viewport[2])/viewport[3], 0.1, 1000)
		glMatrixMode(GL_MODELVIEW)
		glLoadIdentity()
		glClearColor( 0.5, 0.5, 0.5, 1 )
	def render(self):
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT )
		glLoadIdentity( )

		# Position camera to look at the world origin.
		gluLookAt( 1, 1, 1, 0, 0, 0, 0, 0, 1 )

		# Draw x-axis line.
		glColor3f( 1, 0, 0 )

		glBegin( GL_LINES )
		glVertex3f( 0, 0, 0 )
		glVertex3f( 1, 0, 0 )
		glEnd( )

		# Draw y-axis line.
		glColor3f( 0, 1, 0 )

		glBegin( GL_LINES )
		glVertex3f( 0, 0, 0 )
		glVertex3f( 0, 1, 0 )
		glEnd( )

		# Draw z-axis line.
		glColor3f( 0, 0, 1 )

		glBegin( GL_LINES )
		glVertex3f( 0, 0, 0 )
		glVertex3f( 0, 0, 1 )
		glEnd( )
		lx = len(self.objects)
		ly = len(self.objects[0])
		lz = len(self.objects[0][0])
		ry = xrange(len(self.objects[0]))
		rz = xrange(len(self.objects[0][0]))
		sx = 1./lx
		sy = 1./ly
		sz = 1./lz
		for x in xrange(lx):
			for y in ry:
				for z in rz:
					if (self.objects[x][y][z] == 0):
						continue
					glColor(self.calcspace[x][y][z]/10, 0, 0)
					glBegin(GL_QUADS)
					glVertex3f(x*sx,y*sy,z*sz);
					glVertex3f((x+1)*sx,y*sy,z*sz);
					glVertex3f((x+1)*sx,(y+1)*sy,z*sz);
					glVertex3f(x*sx,(y+1)*sy,z*sz);
					glEnd()

		pygame.display.flip( )		

if __name__ == '__main__':
	eng = Engine(10,10,10,lambda i, j, k: i*0+3, 0.05, 0.5)
	eng.insertObject(3, 3, 3, 3, 3, 3, lambda i, j, k: i*0+10, 0.05)
	eng.initRender([640, 480])
	#eng.moveObject(1,5,5,5, True)
	for i in xrange(10):
		eng.iterate(1)
	eng.render()
	raw_input("Press enter")
