// Gzowo Glass — print-ready parametric frame (OpenSCAD 2021.01)
// ---------------------------------------------------------------------------
// Frame of reference (mm): X = wearer's right, Y = forward (away from the
// face), Z = up. The right pupil axis is the line (PD/2, *, 0). The back face
// of the front frame is the plane y = 0; the cornea sits at y = -VD.
//
// Architecture
//   FRONT  rims + brow bar + right "hood" (beam channel, lens seat, beam
//          splitter slot). One flat print, back face on the bed.
//   PODS   rigid boxes screwed to both ends of the front (no hinge in the
//          optical path, no wire crosses a hinge except the speaker pair).
//          right pod: XIAO ESP32-S3 Sense (camera to the front wall), 0.96"
//          OLED facing +Y, 30x15 fold mirror at 45°, MAX98357 at the back,
//          push button on top, USB-C through the lid.
//          left pod: battery (counterweight) + status LED.
//   TEMPLES hinged at the rear of each pod (M2.5x12 screws as pins), speaker
//          in the right temple at the ear.
//   LIDS   outer plates of the pods, 4x M2.5 each.
//
// Optical path: OLED (y=OLED_Y, screen +Y) -> mirror (MIR_C) -> along -X
// inside the hood -> lens f=50 (LENS_X, axis X) -> beam splitter (COMB, 45°
// about Z) -> eye. OLED->lens = 42 mm => virtual image ~26 cm away; the eye
// looks up ~25° into the hood (see ../RESEARCH.md).
// ---------------------------------------------------------------------------

part = "assembly";   // front | pod_r | pod_l | lid_r | lid_l | temple_r | temple_l | assembly | fit
show_parts = true;   // ghost electronics/optics in assembly/fit
$fn = 40;

// ------------------------------------------------------------ head / fit ---
PD       = 63;    // pupil distance
VD       = 14;    // vertex distance (cornea -> frame back)
NOSE_W   = 18;    // nose width at the eyes
TEMPLE_L = 100;   // hinge -> ear
EX       = PD/2;

// ------------------------------------------------------- component sizes ---
XIAO     = [21, 17.8, 15];      // XIAO ESP32-S3 Sense stack incl. camera (footprint x,y; height z)
OLED_PCB = [27.3, 27.3, 4.3];   // 0.96" I2C module; active area sits ~4 mm below board centre
AMP      = [19.4, 17.8, 3.2];   // MAX98357 breakout
SPK_D    = 20;  SPK_T = 3.6;    // speaker
BS       = [30, 30, 1.6];       // beam splitter plate (thickness assumed; slot = 2.2)
MIR      = [30, 15, 1.6];       // fold mirror (first-surface), width x height
LENS_D   = 30;  LENS_T = 6.5;   // biconvex f=50, centre thickness ~6
BTN      = [6, 6, 5];           // tact switch
BAT      = [40, 20, 8];         // battery pocket (y, z, x) -> edit when the cell is known
S_TAP    = 2.2;  S_CLR = 2.8;  S_HEAD = 5.2;   // M2.5 self-tap / clearance / head
CLR      = 0.4;  WALL = 1.6;

// ---------------------------------------------------------------- layout ---
FRONT_T  = 6;                  // front plate depth (y 0..6)
BAR_Z0   = 6;   BAR_Z1 = 22;   // brow bar z-range (16 tall)
BEAM_Z   = 12.5;               // optical axis height inside the bar
BEAM_H   = 11.4;               // beam channel height (OLED image 10.9 + margin)
BEAM_W   = 22;                 // beam channel depth in y (OLED image 21.7)
COMB     = [EX, 13, BEAM_Z-6]; // beam splitter centre; beam hits 9 mm below its top edge
HOOD_X0  = 15;  HOOD_X1 = 66;  // hood spans the right lens to the pod
HOOD_D   = COMB[1] + BEAM_W/2 + 2;   // hood depth (y 0..26)
LENS_X   = 70;                 // lens centre (axis X), seat just inside the right pod's inner wall
POD      = [32, 58, 42];       // pod size x,y,z (z from POD_Z0)
POD_Z0   = -4;                 // pod bottom (lens Ø30 needs room below the beam axis)
POD_CX   = 82;                 // pod centre x (inner wall at 66, outer at 98)
POD_CY   = -1;                 // pod y-range -30..28
MIR_C    = [POD_CX, COMB[1], BEAM_Z];             // fold mirror centre
OLED_Y   = MIR_C[1] - (42 - (MIR_C[0] - LENS_X)); // screen plane y: OLED->mirror->lens = 42
HINGE    = [POD_CX, POD_CY - POD[1]/2 - 4];       // temple hinge axis (x, y), behind the pod
TEMPLE_W = 12;  TEMPLE_H = 14;  TEMPLE_Z = 19;
LID_T    = 2;

// --------------------------------------------------------------- helpers ---
module rbox(size, r=2) { // rounded box centred at origin
    hull() for (i=[-1,1], j=[-1,1], k=[-1,1])
        translate([i*(size[0]/2-r), j*(size[1]/2-r), k*(size[2]/2-r)]) sphere(r=r, $fn=20);
}
module rboxc(p, size, r=2) translate(p + size/2) rbox(size, r);   // rounded box from corner p
module plate(d) rotate([90,0,0]) translate([0,0,-d]) linear_extrude(height=d) children(); // 2D (x,z) -> +y 0..d
module lens2d(mir=false) // wayfarer opening, right eye; mirrored for the left
    scale([mir ? -1 : 1, 1]) offset(r=3) offset(r=-3)
        polygon([[6,6],[50,6],[52,-2],[48,-14],[40,-20],[20,-21],[9,-17],[5,-6]]);
module tap(l)  cylinder(d=S_TAP, h=l);
module clr(l)  cylinder(d=S_CLR, h=l);
module head(l=3) cylinder(d=S_HEAD, h=l);

// ================================================================= FRONT ====
module front_solid() {
    for (m=[false,true]) plate(FRONT_T) offset(r=5) lens2d(m);                 // rims
    translate([-HOOD_X1, 0, BAR_Z0]) cube([2*HOOD_X1, FRONT_T, BAR_Z1-BAR_Z0]); // brow bar
    translate([HOOD_X0, 0, BAR_Z0]) cube([HOOD_X1-HOOD_X0, HOOD_D, BAR_Z1-BAR_Z0]); // hood
    // plug ends: right = hood end (x 66..70), left = bar end (x -66..-76)
    translate([HOOD_X1, 0, BAR_Z0]) cube([4, HOOD_D, BAR_Z1-BAR_Z0]);
    translate([-HOOD_X1-10, 0, BAR_Z0]) cube([10, FRONT_T, BAR_Z1-BAR_Z0]);
    for (s=[-1,1]) translate([s*(NOSE_W/2+1)-2, -3.5, -14]) rboxc([0,0,0], [4, 7, 12], 1.5); // nose pads
}
module front_cuts() {
    for (m=[false,true]) {
        translate([0,-1,0]) plate(FRONT_T+2) lens2d(m);              // opening
        translate([0,-1,0]) plate(3.4) offset(r=1) lens2d(m);        // 2.4 mm rebate from the back for the tinted lens
    }
    // beam channel: from the hood end to just past the beam splitter
    translate([COMB[0]-2, COMB[1]-BEAM_W/2, BEAM_Z-BEAM_H/2]) cube([HOOD_X1+6-COMB[0], BEAM_W, BEAM_H]);
    // beam splitter slot, 45° about Z, from below the bar up into the hood
    translate(COMB) rotate([0,0,45]) cube([BS[0]+0.8, BS[2]+0.6, BS[1]+0.8], center=true);
    // eye window: open the hood's back where the reflected beam exits
    translate([COMB[0]-BEAM_W/2-1, -1, BEAM_Z-BEAM_H/2]) cube([BEAM_W+2, 4, BEAM_H]);
    // battery wire groove along the top-back edge of the bar (2.6 x 2.6), left pod -> right pod
    translate([-HOOD_X1-10, -0.1, BAR_Z1-2.6]) cube([2*HOOD_X1+16, 2.6, 2.7]);
    // screw holes in the plug ends (tapped, screws come from the pod bottoms)
    for (y=[1.6, HOOD_D-1.6]) translate([HOOD_X1+2, y, BAR_Z0-1]) tap(9);
    for (x=[-HOOD_X1-3, -HOOD_X1-8]) translate([x, 3, BAR_Z0-1]) tap(9);
}
module front() difference() { front_solid(); front_cuts(); }

// ================================================================== PODS ====
module pod_shell(s) rboxc([s>0 ? POD_CX-POD[0]/2 : -POD_CX-POD[0]/2, POD_CY-POD[1]/2, POD_Z0], POD, 4);
module pod_cavity(s) {
    x0 = s>0 ? POD_CX-POD[0]/2+WALL : -POD_CX-POD[0]/2-1;   // open toward the outer side (lid)
    translate([x0, POD_CY-POD[1]/2+WALL, POD_Z0+WALL]) cube([POD[0]-WALL+1, POD[1]-2*WALL, POD[2]-2*WALL]);
}
module lid_bosses(s) { // corner bosses with tapped holes for the lid screws
    ox = s>0 ? POD_CX+POD[0]/2 : -(POD_CX+POD[0]/2);
    for (y=[POD_CY-POD[1]/2+WALL, POD_CY+POD[1]/2-WALL-6]) for (z=[POD_Z0+WALL, POD_Z0+POD[2]-WALL-6])
        difference() {
            translate([s>0 ? ox-LID_T-8 : ox+LID_T, y, z]) cube([8, 6, 6]);
            translate([s>0 ? ox-LID_T-9 : ox+LID_T-1, y+3, z+3]) rotate([0,90,0]) tap(10);
        }
}
module hinge_knuckles(s) { // pod side: top and bottom knuckles behind the rear wall
    hx = s*HINGE[0];
    for (z=[[POD_Z0,POD_Z0+8],[POD_Z0+POD[2]-8,POD_Z0+POD[2]]]) hull() {
        translate([hx, HINGE[1], z[0]]) cylinder(r=4.5, h=z[1]-z[0]);
        translate([hx-4.5, HINGE[1]+3, z[0]]) cube([9, 3, z[1]-z[0]]);
    }
}
module pod_right_cuts() {
    // hood socket through the inner wall (x 66..70)
    translate([POD_CX-POD[0]/2-1, -0.2, BAR_Z0-0.2]) cube([5, HOOD_D+0.4, BAR_Z1-BAR_Z0+0.4]);
    // beam passage continues past the socket to the mirror
    translate([POD_CX-POD[0]/2-1, COMB[1]-BEAM_W/2, BEAM_Z-BEAM_H/2]) cube([12, BEAM_W, BEAM_H]);
    // lens seat: cylindrical pocket along X just inside the inner wall (lens dropped in from the lid side)
    translate([LENS_X-LENS_T/2-CLR, COMB[1], BEAM_Z]) rotate([0,90,0]) cylinder(d=LENS_D+2*CLR, h=LENS_T+2*CLR);
    // screws from the bottom into the hood end walls
    for (y=[1.6, HOOD_D-1.6]) { translate([POD_CX-POD[0]/2+2, y, POD_Z0-1]) clr(WALL+6+4); translate([POD_CX-POD[0]/2+2, y, POD_Z0-0.1]) head(1.6); }
    // OLED slot: board in the XZ plane, screen facing +Y; active area 4 mm below board centre
    translate([POD_CX-OLED_PCB[0]/2-CLR, OLED_Y-OLED_PCB[2]-CLR, BEAM_Z+4-OLED_PCB[1]/2-CLR])
        cube([OLED_PCB[0]+2*CLR+6, OLED_PCB[2]+2*CLR, OLED_PCB[1]+2*CLR]);
    // fold mirror slot: plane along (1,-1,0), 45° about Z
    translate(MIR_C) rotate([0,0,-45]) cube([MIR[0]+0.8, MIR[2]+0.6, MIR[1]+0.8], center=true);
    // camera window in the front wall (XIAO lies flat above the beam, camera FPC bends to the wall)
    translate([POD_CX+6, POD_CY+POD[1]/2-WALL-1, 31]) rotate([-90,0,0]) cylinder(d=6.5, h=WALL+2);
    // push-to-talk button through the top wall
    translate([POD_CX-4, -8, POD_Z0+POD[2]-WALL-1]) cylinder(d=BTN[0]+1.2, h=WALL+2);
    // speaker wires to the temple: hole next to the hinge
    translate([POD_CX+6, POD_CY-POD[1]/2-1, TEMPLE_Z-1.5]) cube([3, WALL+2, 3]);
    // battery wires from the bar groove
    translate([POD_CX-POD[0]/2-1, -0.1, BAR_Z1-2.6]) cube([5, 2.6, 2.7]);
}
module pod_left_cuts() {
    // bar socket through the inner wall (x -66..-76)
    translate([-POD_CX+POD[0]/2-10, -0.2, BAR_Z0-0.2]) cube([11, FRONT_T+0.4, BAR_Z1-BAR_Z0+0.4]);
    for (x=[-HOOD_X1-3, -HOOD_X1-8]) { translate([x, 3, POD_Z0-1]) clr(WALL+6+4); translate([x, 3, POD_Z0-0.1]) head(1.6); }
    translate([-POD_CX+POD[0]/2-4, -0.1, BAR_Z1-2.6]) cube([5, 2.6, 2.7]);        // wire groove exit
    translate([-POD_CX-6, POD_CY+POD[1]/2-WALL-1, 31]) rotate([-90,0,0]) cylinder(d=3.2, h=WALL+2); // LED
}
module pod(s) {
    difference() {
        union() { pod_shell(s); hinge_knuckles(s); }
        pod_cavity(s);
        if (s>0) pod_right_cuts(); else pod_left_cuts();
        // hinge: clearance through the knuckles, heads recessed top and bottom
        translate([s*HINGE[0], HINGE[1], POD_Z0-1]) clr(POD[2]+2);
        translate([s*HINGE[0], HINGE[1], POD_Z0+POD[2]-2.4]) head(3);
        translate([s*HINGE[0], HINGE[1], POD_Z0-0.5]) head(2.9);
    }
    difference() { lid_bosses(s); pod_cavity_keep(s); }
}
module pod_cavity_keep(s) { } // bosses live inside the cavity; nothing to subtract
module lid(s) {
    ox = s>0 ? POD_CX+POD[0]/2-LID_T : -(POD_CX+POD[0]/2);
    difference() {
        translate([ox, POD_CY-POD[1]/2+WALL+CLR/2, POD_Z0+WALL+CLR/2]) cube([LID_T, POD[1]-2*WALL-CLR, POD[2]-2*WALL-CLR]);
        for (y=[POD_CY-POD[1]/2+WALL+3, POD_CY+POD[1]/2-WALL-3]) for (z=[POD_Z0+WALL+3, POD_Z0+POD[2]-WALL-3])
            translate([ox-1, y, z]) rotate([0,90,0]) { clr(LID_T+2); translate([0,0,LID_T+0.2]) head(3); }
        if (s>0) translate([ox-1, 10.5, 19]) cube([LID_T+2, 9.6, 4]);   // USB-C window (XIAO main board at the bottom of the stack, port faces +X)
    }
}

// =============================================================== TEMPLES ====
module temple(s) {
    hx = s*HINGE[0]; hy = HINGE[1];
    difference() {
        union() {
            translate([hx, hy, POD_Z0+8.3]) cylinder(r=4.5, h=POD[2]-16.6);             // knuckle
            hull() {                                                                    // root
                translate([hx, hy, POD_Z0+8.3]) cylinder(r=4.5, h=POD[2]-16.6);
                rboxc([hx-TEMPLE_W/2, hy-14, TEMPLE_Z-TEMPLE_H/2], [TEMPLE_W, 8, TEMPLE_H], 2);
            }
            rboxc([hx-TEMPLE_W/2, hy-TEMPLE_L, TEMPLE_Z-TEMPLE_H/2], [TEMPLE_W, TEMPLE_L-6, TEMPLE_H], 2.5); // arm
            translate([hx, hy-TEMPLE_L+2, TEMPLE_Z]) rotate([-30,0,0]) rboxc([-4, -44, -5], [8, 46, 10], 2);   // ear hook
            if (s>0) translate([hx-TEMPLE_W/2, hy-TEMPLE_L+16, TEMPLE_Z]) rotate([0,90,0]) cylinder(d=SPK_D+5, h=7); // speaker boss
        }
        translate([hx, hy, POD_Z0-1]) clr(POD[2]+2);                                    // hinge screw
        translate([hx-1.4, hy-TEMPLE_L+14, TEMPLE_Z-1.4]) cube([2.8, TEMPLE_L-20, 2.8]); // wire channel
        if (s>0) {
            cy = hy-TEMPLE_L+16;
            translate([hx-TEMPLE_W/2-1, cy, TEMPLE_Z]) rotate([0,90,0]) cylinder(d=SPK_D+2*CLR, h=SPK_T+CLR+1);
            for (a=[0:60:300]) translate([hx-TEMPLE_W/2-1, cy+6*cos(a), TEMPLE_Z+6*sin(a)]) rotate([0,90,0]) cylinder(d=2, h=10);
            translate([hx-TEMPLE_W/2-1, cy, TEMPLE_Z]) rotate([0,90,0]) cylinder(d=2, h=10);
        }
    }
}

// ================================================================ GHOSTS ====
module ghosts() {
    color("blue", 0.7)   translate([POD_CX-OLED_PCB[0]/2, OLED_Y-OLED_PCB[2], BEAM_Z+4-OLED_PCB[1]/2]) cube([OLED_PCB[0], OLED_PCB[2], OLED_PCB[1]]);
    color("silver", 0.9) translate(MIR_C) rotate([0,0,-45]) cube([MIR[0], MIR[2], MIR[1]], center=true);
    color("cyan", 0.5)   translate([LENS_X, COMB[1], BEAM_Z]) rotate([0,90,0]) cylinder(d=LENS_D, h=LENS_T, center=true);
    color("cyan", 0.4)   translate(COMB) rotate([0,0,45]) cube([BS[0], BS[2], BS[1]], center=true);
    color("green", 0.6)  translate([POD_CX-XIAO[0]/2+3, 7, BEAM_Z+MIR[1]/2+0.8]) cube(XIAO);          // XIAO flat above the mirror (z 20.8..35.8)
    color("red", 0.7)    translate([POD_CX-AMP[0]/2, POD_CY-POD[1]/2+WALL+0.4, 2]) cube([AMP[0], AMP[2], AMP[1]]); // amp at the back wall
    color("orange", 0.7) translate([-POD_CX-4, POD_CY-BAT[0]/2, 8]) cube([BAT[2], BAT[0], BAT[1]]);
    color("gray", 0.7)   translate([HINGE[0]-TEMPLE_W/2, HINGE[1]-TEMPLE_L+16, TEMPLE_Z]) rotate([0,90,0]) cylinder(d=SPK_D, h=SPK_T);
    color("yellow", 0.3) translate([POD_CX-BEAM_W/2, OLED_Y, BEAM_Z-5.45]) cube([BEAM_W, MIR_C[1]-OLED_Y, 10.9]);
    color("yellow", 0.3) translate([COMB[0], COMB[1]-BEAM_W/2, BEAM_Z-5.45]) cube([MIR_C[0]-COMB[0], BEAM_W, 10.9]);
    color("yellow", 0.3) translate([COMB[0]-BEAM_W/2, -VD, BEAM_Z-5.45]) cube([BEAM_W, COMB[1]+VD, 10.9]);
}

// ================================================================ OUTPUT ====
module assembly() {
    color("dimgray") front();
    color("dimgray") { pod(1); pod(-1); }
    color("darkslategray") { lid(1); lid(-1); }
    color("dimgray") { temple(1); temple(-1); }
    if (show_parts) ghosts();
}
if (part == "front") front();
else if (part == "pod_r") pod(1);
else if (part == "pod_l") pod(-1);
else if (part == "lid_r") lid(1);
else if (part == "lid_l") lid(-1);
else if (part == "temple_r") temple(1);
else if (part == "temple_l") temple(-1);
else if (part == "fit") { %front(); %pod(1); %pod(-1); ghosts(); }
else assembly();
