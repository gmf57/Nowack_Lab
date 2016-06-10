# TO DO: 	- Try sweep vs individual points
# 			- Write preamp driver
#			- Instruments as a dict... change this in other code?
#			- Build in acceleration to daq sweep to and from zero?
# 			- Do up and down sweeps?

from IPython import display
import matplotlib.pyplot as plt
import numpy as np

class SquidIV():
    def __init__(self, instruments, squidout, squidin, modout, rate):    
        self.daq = instruments['daq']
        self.preamp = instruments['preamp']
        self.montana = instruments['montana']
        
        self.squidout = squidout
        self.squidin = squidin
        self.modout = modout
        
        self.filename = time.strftime('%Y%m%d_%H%M%S') + '_IV'

        self.rate = rate # Hz # measurement rate of the daq
        self.preamp.gain = 500 
        self.preamp.filter = (0, rate) # Hz  
        
        self.Rbias = 2e3 # Ohm # 1k cold bias resistors on the SQUID testing PCB
        self.Rbias_mod = 2e3 # Ohm # 1k cold bias resistors on the SQUID testing PCB
        self.I_mod = 0 # A # constant mod current
        
        self.Irampspan = 200e-6 # A # Will sweep from -Irampspan/2 to +Irampspan/2
        self.Irampstep = 0.5e-6 # A # Step size
        self.numpts = int(self.Irampspan/self.Irampstep)		
        self.I = np.linspace(-self.Irampspan/2, self.Irampspan/2, self.numpts) # Squid current
        self.Vbias = self.I*self.Rbias # SQUID bias voltage
        
        self.Vbias_mod = self.I_mod*self.Rbias_mod # Mod bias voltage
        
        self.V = [] # Measured voltage
        
        self.fig = plt.figure()
        self.ax = plt.gca()
        display.clear_output()
               
    def do(self):
        self.param_prompt() # Check parameters
        setattr(self.daq, self.modout, self.Vbias_mod) # Set mod current
        
        # Collect data
        Vout, Vin, time = self.daq.sweep(self.squidout, self.Vbias[0], self.Vbias[-1], freq=self.rate)
        self.V = Vin/self.preamp.gain
        
        self.plot()
        inp = input('Press enter to save data, type anything else to quit. ')
        if inp == '':
        	self.save()
        
        setattr(self.daq, self.modout, 0) # Zero mod current
                          
	def param_prompt(self):
		""" Check and confirm values of parameters """
		for param in ['rate', 'Rbias', 'Rbias_mod', 'Imod', 'Irampspan', 'Irampstep']:
			print(param, ': ', getattr(self, param), '\n')
		for paramamp in ['gain','filter']:
			print('preamp ', param, ': ', getattr(self.preamp, paramamp), '\n')
		correct = False
		while not correct:
			if self.rate > self.preamp.filter_high:
				print("You're filtering out your signal... fix the preamp cutoff\n")
			if self.Irampspan > 200e-6:
				print("You want the SQUID biased above 100 uA?... don't kill the SQUID!\n")
			
			inp = input('Are these parameters correct? Enter a command to change parameters, or press enter to continue (e.g. preamp.gain = 100): ')
			if inp == '':
				correct = True
			else:
				eval('self.'+inp)
         
    def plot(self):
        plt.clf()

        plt.plot(self.I*1e6, self.V, 'k-')
        plt.title('self.filename') # NEED DESCRIPTIVE TITLE
        plt.xlabel(r'$I_{bias} = V_{bias}/R_{bias}$ ($\mu$ A)', fontsize=20)
        plt.ylabel(r'$V_{squid}$ (V)', fontsize=20)
                
        display.display(self.fig)
        
    def save(self):
        data_folder = 'C:\\Users\\Hemlock\\Dropbox (Nowack lab)\\TeamData\\Montana\\squid_testing\\IV\\'

        filename = data_folder + self.filename
        with open(filename+'.csv', 'w') as f:
            f.write('Montana info: \n'+self.montana.log()+'\n')
            for param in ['rate', 'Rbias', 'Rbias_mod', 'Imod', 'Irampspan', 'Irampstep']:
                f.write(param + ': ' + getattr(self, param) + '\n')
            for paramamp in ['gain','filter']:
                f.write('preamp ' + param + ': ' + getattr(self.preamp, paramamp) + '\n') 
            f.write('I (A)\tV (V)\n')
            for i in range(len(self.V)):
                f.write('%f' %self.I[i] + '\t' + '%f' %self.V[i] + '\n')

        plt.savefig(filename+'.pdf', bbox_inches='tight')