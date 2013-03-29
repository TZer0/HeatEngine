from numpy import fromfunction, zeros, max, min, array, cross, dot, arccos
import pygame
from pygame.locals import *
from OpenGL.GL import *
from OpenGL.GLU import *
from qmath import quaternion

def normVec(vec):
	return vec/sum(vec**2)

class Engine:
	def __init__(self, x, y, z, temp, k=0.05, spacing = 0.1):
		self.calcspace = fromfunction(temp, (x,y,z), dtype=float)
		self.middlePoint = self.calcspace[x/2][y/2][z/2]
		self.prev = self.calcspace.copy()
		self.objects = zeros((x,y,z), dtype=int)
		self.nextObj = 1
		self.startTemp = temp(0,0,0)
		self.kVals = [[k]]
		self.spacing = spacing
		self.Time = 0.;
		

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
		self.Time += dt
		pre = dt/self.spacing**2
		ys = len(self.calcspace[0])
		zs = len(self.calcspace[0][0])
		obj = self.objects
		kV = self.kVals
		prev = self.prev
		calcSp = self.calcspace
		#print calcSp

		#print pre
		#print 0.51*dt*dt
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
					#print "n %f %f %f" % (calcSp[x][y][z], calc*pre, kV[obj[x][y][z]][0])
		tmp = self.calcspace
		self.calcspace = self.prev
		self.prev = tmp
		#print self.calcspace
	def initRender(self, size):
		self.size = size
		pygame.init()
		self.font = pygame.font.SysFont("Bitstream Vera Sans Mono", 14)
		self.screen = pygame.display.set_mode(size, HWSURFACE | OPENGL | DOUBLEBUF)
		glViewport(0, 0, size[0], size[1])
		glShadeModel(GL_SMOOTH)
		glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST)
		self.viewport = glGetIntegerv( GL_VIEWPORT )
		glClearColor( 0.5, 0.5, 0.5, 1 )
	def render(self):
		glClear( GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT )
		glEnable(GL_BLEND)
		glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

		glMatrixMode(GL_PROJECTION)
		glLoadIdentity()

		gluPerspective(60.0, float(self.viewport[2])/self.viewport[3], 0.1, 1000)

		glMatrixMode(GL_MODELVIEW)
		glLoadIdentity( )

		# Position camera to look at the world origin.
		gluLookAt( 1, 1, 1, 0, 0, 0, 0, 0, 1 )
		temp = self.rot.QuaternionToRotation()
		rotMat = zeros((4,4), dtype=float)
		for i in xrange(3):
			for j in xrange(3):
				rotMat[i,j] = temp[i,j]
		rotMat[3,3] = 1
		glMultMatrixf(rotMat)

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
		maxTemp = max(self.calcspace)
		minTemp = min(self.calcspace)
		mid = self.middlePoint
		if (abs(maxTemp-mid) < 1 ):
			maxTemp = mid + 1
		if (abs(minTemp-mid) < 1):
			minTemp = mid - 1
		calc = self.calcspace
		obj = self.objects
		for x in xrange(lx):
			for y in ry:
				for z in rz:
					if (obj[x][y][z] == 0):
						continue
					colFac = (calc[x][y][z] >= mid)*((calc[x][y][z]-mid)/(maxTemp-mid)) +\
						 (calc[x][y][z] < mid)*((calc[x][y][z]-mid)/(minTemp-mid)) 
					glColor(colFac, 0, 1-colFac, 0.5)
					glBegin(GL_QUADS)
					#top
					glVertex3f(x*sx,y*sy,(z+1)*sz);
					glVertex3f((x+1)*sx,y*sy,(z+1)*sz);
					glVertex3f((x+1)*sx,(y+1)*sy,(z+1)*sz);
					glVertex3f(x*sx,(y+1)*sy,(z+1)*sz);
					#bottom
					glVertex3f(x*sx,y*sy,z*sz);
					glVertex3f((x+1)*sx,y*sy,z*sz);
					glVertex3f((x+1)*sx,(y+1)*sy,z*sz);
					glVertex3f(x*sx,(y+1)*sy,z*sz);
					#side 1
					glVertex3f(x*sx,y*sy,z*sz);
					glVertex3f(x*sx,y*sy,(z+1)*sz);
					glVertex3f(x*sx,(y+1)*sy,(z+1)*sz);
					glVertex3f(x*sx,(y+1)*sy,z*sz);
					#side 2
					glVertex3f((x+1)*sx,y*sy,z*sz);
					glVertex3f((x+1)*sx,y*sy,(z+1)*sz);
					glVertex3f((x+1)*sx,(y+1)*sy,(z+1)*sz);
					glVertex3f((x+1)*sx,(y+1)*sy,z*sz);
					#side 3
					glVertex3f((x+1)*sx,(y+1)*sy,z*sz);
					glVertex3f((x+1)*sx,(y+1)*sy,(z+1)*sz);
					glVertex3f(x*sx,(y+1)*sy,(z+1)*sz);
					glVertex3f(x*sx,(y+1)*sy,z*sz);
					#side 4
					glVertex3f((x+1)*sx,y*sy,z*sz);
					glVertex3f((x+1)*sx,y*sy,(z+1)*sz);
					glVertex3f(x*sx,y*sy,(z+1)*sz);
					glVertex3f(x*sx,y*sy,z*sz);
					glEnd()
		glMatrixMode(GL_MODELVIEW)
		glLoadIdentity( )
		glMatrixMode(GL_PROJECTION)
		glLoadIdentity()

		glBegin(GL_QUADS)
		glColor(0, 0, 1, 1)
		glVertex2f(-0.2,-1)
		glVertex2f(-0.2,-0.94)
		glColor(1, 0, 0, 1)
		glVertex2f(0.2,-0.94)
		glVertex2f(0.2,-1)
		glEnd()
		# Position camera to look at the world origin.
		for dat in ((-0.4, -1., "%3f", minTemp), 
				(0.2 , -1., "%3f", maxTemp),
				(-0.1, -0.94, "%3f", self.middlePoint),
				(-1, 0.94, "T: %3f", self.Time)):
			glRasterPos2f(dat[0], dat[1]);
			minText = self.font.render(dat[2] % (dat[3]), 1, (255, 255, 255), (0,0,0))
			minData = pygame.image.tostring(minText, 'RGBA', 1)
			minSize = minText.get_size()
			glDrawPixels(minSize[0], minSize[1], GL_RGBA, GL_UNSIGNED_BYTE, minData)
		glFlush()
		pygame.display.flip()
		glLoadIdentity( )
	def run(self, size):
		self.rot = quaternion(array([[1.,0.,0.], [0.,1.,0.], [0.,0.,1.]]))
		self.initRender(size)
		framerate = 20
		pygame.time.set_timer(pygame.VIDEOEXPOSE, 1000 / framerate)
		while True:
			self.rot = self.rot.unitary()
			event = pygame.event.wait()
			if event.type == pygame.VIDEOEXPOSE:
				eng.iterate(0.01)
				self.render()
			elif event.type == pygame.KEYDOWN and event.key == pygame.K_q:
				break;
			elif event.type == pygame.MOUSEMOTION:
				if event.buttons[0] == 1:
					v1 = self.getVector(self.oldPos)
					v2 = self.getVector(event.pos)
					cr = cross(v2, v1)
					d = dot(v1, v2)
					print arccos(d)
					print cr
				self.oldPos = event.pos

			else:
				pass
				#print event

		
	def getVector(self, pos):
		xm = pos[0]/(float(self.size[0]))-0.5
		ym = 0.5-pos[1]/(float(self.size[1]))
		r = (xm*xm + ym*ym)**0.5
		if r >= 0.5:
			xm /= r
			ym /= r
			lComp = 0
		else:
			xm *= 2
			ym *= 2
			lComp = (1-4*r*r)**0.5
		return normVec(array([xm, ym, lComp]))
		#return glm::normalize(glm::vec3(xm, ym, lComp));

if __name__ == '__main__':
	eng = Engine(10,10,10,lambda i, j, k: i*0+3, 0.05, 0.5)
	eng.insertObject(3, 3, 3, 3, 3, 3, lambda i, j, k: i*0+10, 0.05)
	#eng.moveObject(1,5,5,5, True)
	eng.run([640, 480])

