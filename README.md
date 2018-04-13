#ngspice-ccam

This is a fork o ngspice version 27 available at http://ngspice.sourceforge.net modified to compile with the CCAM CNTFET model (https://nanohub.org/publications/62/2). The CCAM model is provided as a Verilog-A compact model and this repository brings the adapted ngspice source files to make the model available at the simulator.

# Install instructions

On Debian systems do
```sudo apt-get install bison flex libx11-dev autoconf automake libtool texinfo libreadline-dev tcl libfftw3-dev libxaw-dev
```

Go to the build folder, configure and compile the project:
```
./reconfigure
make
make install
```

The script installs the binary to `$HOME/.local/ngspice`. You have to adjust your path:
```
export PATH=$HOME/.local/ngspice/bin:$PATH
```

# Usage
In the spice netlist (note that the order of nodes changes from other MOSFET models:

```
M<name> <VD> <VG> <VS> cntfet

.model cntfet nmos level=99
+idstn="0.25592"      vthin="-0.17594"     vth0in="35.662" 
+athin="18.029"       sthin="0.2"          idstp="0" 
+vthip="-0.032389"    vth0ip="84.762"      athip="9.0461" 
+sthip="0.2"          vdcr="1.5854"        betdcr="1.0266" 
+smss="10"            facss="1"            rscs="27.1845" 
+rdcs="12.1844"       ctn0="1.0274e-13"    ctp0="1.0274e-13" 
+vthqs="-0.1"         vth0qs="0.66693"     athqs="3" 
+vthqd="-1.1"         vth0qd="3.0386"      athqd="2.6667" 
+pqsd="0.16667"       rmta="132236.5698"   amto="117945.2195" 
+cmt="1.8152e-17"     pqmt="0.49425"       rscm="47306.2244" 
+rdcm="47306.2244"    fanof="1"            fanofmt="1" 
+hoogef="0.002"       beta_fn="1"          rsf="0.001" 
+rdf="0.001"          rg="1"               cgspar1="0" 
+cgspar2="2.4844e-14" cgdpar1="2.7819e-15" cgdpar2="2.7819e-15" 
+cdspar="2.4e-14"     tnom="26.85"         rths="0" 
+rthm="0" zetrmta="0" zetamto="0"          alvthin="0" 
+alvth0in="0"         alvthip="0"          alvth0ip="0" 
+alidst="0"           alct0="0"            alvthqs="0" 
+alvth0qs="0"         alvthqd="0"          alvth0qd="0" 
+alrscon="0"          alrmcon="0"          atrap="0" 
+btrap="0"            ctrap="0"            w0trap="0" 
+strap="0"
```

For specifics about the CCAM model parameters please refer to the [CCAM model manual](https://nanohub.org/publications/62/serve/2/494?el=6&download=1).

Due to issues with ADMS Verilog-A to C++ translation, the trap network described in the CCAM manual was disabled on this implementation.