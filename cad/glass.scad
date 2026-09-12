// Gzowo Glass v0.6 — print-ready parametric frame (OpenSCAD 2021.01)
// ---------------------------------------------------------------------------
// Frame of reference (mm): X = wearer's right, Y = forward (away from the
// face), Z = up. The right pupil axis is the line (PD/2, *, 0). The back face
// of the front frame is the plane y = 0; the cornea sits at y = -VD.
//
// v0.6 rewrite after the gauntlet review (work/gauntlet/findings):
//   * SINGLE-FOLD OPTICS. The OLED stands in the hood (screen facing -X, long
//     axis along Z) on a slide rail x 60..66 (focus). One first-surface mirror
//     at 45° about Y turns the beam down; the lens f=50 sits in the hood floor
//     right above the beam splitter; the splitter (25x25) is tilted 45° about
//     X on the pupil axis. Two reflections -> upright, un-mirrored image.
//     do = 38..44 mm, lens->eye 47 mm, FOV ~24.7° x 12.5°, image 20..39 cm.
//   * Everything that holds a part is a POSITIVE feature (rails, ribs, floor
//     boss), never a slot that thins a 1.6 mm wall.
//   * The hood and both pods are open at the TOP and closed by lids (M2.5x12,
//     tapped bosses). Print the front UPSIDE DOWN (+Z on the bed): the open
//     cavities face the bed, so the front needs no internal supports.
//   * Pods are fused into the bar/hood with a 2 mm overlap (one solid).
//   * Hinge: bottom knuckle 8 (tapped), temple 5, top 2, gaps 0.5, M2.5x12
//     from the top, 4 mm of thread, head proud. Temples splay OUTWARD.
//   * Wire groove 5x5 on the back of a thicker (8 mm) bar, ends at the hood.
//   * Tinted lens in front of the combiner is a v0.7 item (contrast x5).
// Electronics: LEFT pod = XIAO ESP32-S3 Sense (camera front, USB-C up) +
//   battery. RIGHT pod = MAX98357 + button (in the lid). HOOD = OLED + mirror + lens.
// ---------------------------------------------------------------------------

part = "assembly";   // front | lid_hood | lid_r | lid_l | temple_r | temple_l | assembly | fit | layout | exploded
show_parts = true;   // ghost electronics/optics in assembly/fit
show_head = true;    // ghost of Jurek's head scan (reference/head2-mm.stl)
head_file = "../reference/head2-mm.stl";
$fn = 48;

// ------------------------------------------------------------ head / fit ---
PD       = 62;    // pupil distance (provisional; scan scaled to this)
VD       = 21;    // vertex distance: cornea -> frame back (v0.6: 18 -> 21, the bridge sat inside the nose)
DBL      = 18;    // distance between lenses
PAD_X    = 11.5;  // nose pad centre x
PAD_ANG  = 40;    // pad face angle about Z (deg): face points outward-and-forward like the nose flank
PAD_TILT = 22;    // pad face tilt about X (deg): flank leans back toward the eye
TEMPLE_L = 63;    // hinge -> start of the ear bend
EAR_DROP = 24;    // temple z -> ear top
TEMPLE_SPLAY = 15; // deg, temples open OUTWARD from the hinge (v0.4 had the sign inverted)
EX       = PD/2;

// ------------------------------------------------------- component sizes ---
XIAO     = [21, 17.8, 15];      // XIAO ESP32-S3 Sense stack incl. camera board (x, y footprint; z height of the stack)
OLED_PCB = [27.3, 27.3, 4.3];   // 0.96" I2C module board (w, h, thickness incl. pins). Active area 21.7x10.9.
AMP      = [19.4, 17.8, 3.2];   // MAX98357 breakout
SPK_D    = 20;  SPK_T = 3.6;    // speaker
BS       = [25, 25, 1.1];       // beam splitter plate (v0.6: 25x25; a 30 mm plate collided with the lens)
MIR      = [30, 30, 1.6];       // first-surface mirror, 1 pc
LENS_D   = 30;  LENS_T = 6.5;   // biconvex f=50
BTN      = [6, 6, 5];           // tact switch body
BAT      = [40, 20, 8];         // battery pocket (y, z, x): edit when the cell is known
S_TAP    = 2.4;  S_CLR = 2.9;  S_HEAD = 5.4;  // M2.5x12 in PLA
CLR      = 0.4;  WALL = 1.6;

// ---------------------------------------------------------------- layout ---
FRONT_T  = 6;                  // rim plate depth (y 0..6)
BAR_T    = 8;                  // brow bar depth (y 0..8): the 5x5 wire groove leaves a 3 mm web
BAR_Z0   = 6;   BAR_Z1 = 22;   // brow bar z-range
GROOVE   = [5, 5];             // wire groove w (z) x d (y), on the back of the bar
GROOVE_Z = 11;
// hood (right, over the eye): OLED + mirror + lens, open at the top
HOOD_X0  = 13;  HOOD_X1 = 68;  // x 13..68 (68 = 2 mm INTO the right pod -> fused); 13 so the Ø30.8 lens pocket leaves a 2 mm end wall
HOOD_Y1  = 35;                 // depth y 0..35 (lens pocket Ø30.8 around y = 17.5 leaves 2 mm walls)
HOOD_Z0  = 4;   HOOD_Z1 = 38;  // z 4..38
BEAM_Z   = 22;                 // optical axis height in the hood
AX_Y     = 17.5;               // optical axis y (mirror, lens, splitter all on y = 17.5)
MIR_C    = [EX, AX_Y, BEAM_Z]; // mirror centre; plane at 45° about Y turns the -X beam to -Z
LENS_Z   = 13.4;               // lens centre z (axis Z)
COMB     = [EX, AX_Y, 0];      // splitter centre on the pupil axis, tilted 45° about X, top toward +Y
OLED_X0  = 60;  OLED_X1 = 66;  // OLED slide range (screen face x): do = (x-EX) + (BEAM_Z-LENS_Z) = 37.1..43.1
OLED_X   = 63;                 // nominal -> do = 40.1
// pods
POD_R    = [30, 46, 42];       // right pod (amp + button + wires)
POD_L    = [32, 64, 42];       // left pod (XIAO + battery)
POD_Z0   = -4;
POD_RX   = 66 + POD_R[0]/2;    // right pod centre x (inner wall at 66)
POD_LX   = -(66 + POD_L[0]/2);
POD_RY   = 6;                  // right pod y-range -17..29
POD_LY   = 2;                  // left pod y-range -30..34
// hinge, M2.5x12 from the top: bottom knuckle 8 tapped, temple 5, top 2, gaps 0.5 -> 4 mm of thread, head proud
HK_Z0 = 12; HK_BOT = 8; HK_TEMPLE = 5; HK_TOP = 2; HK_GAP = 0.5;
HK_R  = 5;                     // knuckle radius (bore 2.9 -> 3.5 mm wall)
TEMPLE_W = 12;  TEMPLE_H = 14;
LID_T    = 2.4;
BACK_W   = WALL + 1.4;         // pod back wall 3 mm (carries the hinge)

// --------------------------------------------------------------- helpers ---
module rbox(size, r=2) { hull() for (i=[-1,1], j=[-1,1], k=[-1,1]) translate([i*(size[0]/2-r), j*(size[1]/2-r), k*(size[2]/2-r)]) sphere(r=r, $fn=48); }
module rboxc(p, size, r=2) translate(p + size/2) rbox(size, r);
module plate(d) rotate([90,0,0]) translate([0,0,-d]) linear_extrude(height=d) children(); // 2D (x,z) -> +y 0..d
module lens2d(mir=false) scale([mir ? -1 : 1, 1]) offset(r=3) offset(r=-3)
    polygon([[DBL/2,6],[54,6],[56,-3],[52,-17],[42,-24],[22,-25],[DBL/2+4,-20],[DBL/2,-7]]);
module tap(l)  cylinder(d=S_TAP, h=l);
module clr(l)  cylinder(d=S_CLR, h=l);
module head(l=3) cylinder(d=S_HEAD, h=l);
function pod_c(s)   = s>0 ? [POD_RX, POD_RY, POD_Z0+POD_R[2]/2] : [POD_LX, POD_LY, POD_Z0+POD_L[2]/2];
function pod_sz(s)  = s>0 ? POD_R : POD_L;
function hinge_x(s) = pod_c(s)[0];
function hinge_y(s) = pod_c(s)[1] - pod_sz(s)[1]/2 - 5;   // axis 5 mm behind the pod back wall
function hood_boss_pts() = [[HOOD_X0+WALL+3, WALL+3], [HOOD_X1-WALL-3, WALL+3], [HOOD_X0+WALL+3, HOOD_Y1-WALL-3], [HOOD_X1-WALL-3, HOOD_Y1-WALL-3]];
function pod_boss_pts(s) = let(c = pod_c(s), sz = pod_sz(s))
    [[c[0]-sz[0]/2+WALL+3, c[1]-sz[1]/2+BACK_W+3], [c[0]+sz[0]/2-WALL-3, c[1]-sz[1]/2+BACK_W+3],
     [c[0]-sz[0]/2+WALL+3, c[1]+sz[1]/2-WALL-3],   [c[0]+sz[0]/2-WALL-3, c[1]+sz[1]/2-WALL-3]];

// ================================================================= FRONT ====
module rims() difference() {
    for (m=[false,true]) plate(FRONT_T) offset(r=5) lens2d(m);
    for (m=[false,true]) { translate([0,-1,0]) plate(FRONT_T+2) lens2d(m); translate([0,-1,0]) plate(3.4) offset(r=1) lens2d(m); }
}
module bar() intersection() { rboxc([-70, -4, BAR_Z0], [140, BAR_T+4, BAR_Z1-BAR_Z0], 2.5); translate([-70, 0, BAR_Z0-1]) cube([140, BAR_T, BAR_Z1-BAR_Z0+2]); }
module nose_pads() for (s=[-1,1]) hull() {
    translate([s*PAD_X, -1.5, -10]) rotate([PAD_TILT, 0, s*PAD_ANG]) rbox([3.2, 7, 13], 1.2);
    translate([s*(DBL/2+2.5), 3, -8]) rbox([3, 5, 9], 1);
}
module hood_shell() intersection() { rboxc([HOOD_X0, -4, HOOD_Z0], [HOOD_X1-HOOD_X0, HOOD_Y1+4, HOOD_Z1-HOOD_Z0], 3); translate([HOOD_X0, 0, HOOD_Z0-1]) cube([HOOD_X1-HOOD_X0, HOOD_Y1, HOOD_Z1-HOOD_Z0+2]); }
module hood_cavity() translate([HOOD_X0+WALL, WALL, HOOD_Z0+WALL]) cube([HOOD_X1-HOOD_X0-2*WALL, HOOD_Y1-2*WALL, HOOD_Z1]);   // open at the top
module hood_holders() {
    // OLED rails: rib pairs on the front and back cavity walls; the board slides along x between them
    for (y=[WALL, HOOD_Y1-WALL-1.2]) for (dz=[-1,1]) {
        zc = BEAM_Z + dz*(OLED_PCB[1]/2 + CLR + 0.6);
        translate([OLED_X0-3, y, zc-0.6]) cube([OLED_X1-OLED_X0+OLED_PCB[2]+4, 1.2, 1.2]);
    }
    // mirror ribs: two rib pairs along the 45° plane, 2.4 mm apart; the mirror slides in from the top
    for (y=[WALL+0.6, HOOD_Y1-WALL-0.6]) for (d=[-1,1])
        translate([MIR_C[0], y, MIR_C[2]]) rotate([0,-45,0]) translate([0, 0, d*(MIR[2]/2+CLR+0.6)]) cube([MIR[0]+2, 1.2, 1.2], center=true);
    // lens floor boss: the pocket gets a real floor and a beam window
    translate([EX, AX_Y, HOOD_Z0]) cylinder(d=LENS_D+2*CLR+2.4, h=LENS_Z-LENS_T/2-CLR-HOOD_Z0);
    for (p=hood_boss_pts()) translate([p[0]-3, p[1]-3, HOOD_Z1-10]) cube([6, 6, 10]);
}
module hood_cuts() {
    translate([EX, AX_Y, LENS_Z-LENS_T/2-CLR]) cylinder(d=LENS_D+2*CLR, h=HOOD_Z1);                 // lens pocket from above
    translate([EX-11, AX_Y-7, HOOD_Z0-1]) cube([22, 14, LENS_Z]);                                    // beam window 22x14
    translate(COMB) rotate([-45,0,0]) cube([BS[0]+0.8, BS[2]+0.6, BS[1]+6], center=true);           // splitter slot through the floor
    translate(COMB) rotate([-45,0,0]) translate([0, -(BS[2]+0.6)/2-1.5, 0]) cube([BS[0]+0.8, 3, BS[1]+6], center=true); // no knife edge at the mouth
    translate([HOOD_X0-1, -0.1, GROOVE_Z]) cube([WALL+2, GROOVE[1]+0.1, GROOVE[0]]);                // wires: bar groove -> hood
    translate([HOOD_X1-WALL-3, AX_Y-14, HOOD_Z0+WALL]) cube([WALL+6, 6, 5]);                         // wires: hood -> right pod
    for (p=hood_boss_pts()) translate([p[0], p[1], HOOD_Z1-9]) tap(10);
}
module pod_shell(s) { c = pod_c(s); sz = pod_sz(s); rboxc([c[0]-sz[0]/2, c[1]-sz[1]/2, POD_Z0], sz, 3); }
module pod_cavity(s) { c = pod_c(s); sz = pod_sz(s); translate([c[0]-sz[0]/2+WALL, c[1]-sz[1]/2+BACK_W, POD_Z0+WALL]) cube([sz[0]-2*WALL, sz[1]-WALL-BACK_W, sz[2]]); }
module hinge_knuckles(s) {
    hx = hinge_x(s); hy = hinge_y(s);
    for (z=[[HK_Z0, HK_Z0+HK_BOT], [HK_Z0+HK_BOT+HK_TEMPLE+2*HK_GAP, HK_Z0+HK_BOT+HK_TEMPLE+2*HK_GAP+HK_TOP]]) hull() {
        translate([hx, hy, z[0]]) cylinder(r=HK_R, h=z[1]-z[0]);
        translate([hx-HK_R, hy+3, z[0]]) cube([2*HK_R, 11, z[1]-z[0]]);   // block reaches 6 mm into the pod: load path into the side walls
    }
}
module pod_holders(s) {
    c = pod_c(s); sz = pod_sz(s);
    for (p=pod_boss_pts(s)) translate([p[0]-3, p[1]-3, POD_Z0+sz[2]-10]) cube([6, 6, 10]);
    if (s>0) for (d=[0,1]) translate([c[0]+sz[0]/2-WALL-AMP[2]-2*CLR-1.2 + d*(AMP[2]+2*CLR+1.2), c[1]-AMP[0]/2, POD_Z0+WALL]) cube([1.2, AMP[0], 12]);  // amp ribs
    if (s<0) for (d=[-1,1]) translate([c[0]+2 + d*(XIAO[0]/2+CLR+0.6) - 0.6, c[1]+sz[1]/2-WALL-XIAO[2]-1, POD_Z0+WALL]) cube([1.2, XIAO[2]+1, 10]); // XIAO ribs
}
module pod_cuts(s) {
    c = pod_c(s); sz = pod_sz(s); hx = hinge_x(s); hy = hinge_y(s);
    for (p=pod_boss_pts(s)) translate([p[0], p[1], POD_Z0+sz[2]-9]) tap(10);
    ztop = HK_Z0+HK_BOT+HK_TEMPLE+2*HK_GAP;
    translate([hx, hy, ztop-1]) clr(HK_TOP+2);
    translate([hx, hy, HK_Z0-1]) tap(HK_BOT+2);
    translate([hx, hy, HK_Z0+HK_BOT-0.01]) cylinder(r=HK_R+CLR, h=HK_TEMPLE+2*HK_GAP+0.02);          // free swing for the temple knuckle
    if (s>0) translate([c[0]+4, c[1]-sz[1]/2-1, 16]) cube([3.5, BACK_W+2, 3.5]);                    // speaker wires to the temple
    if (s<0) {
        translate([c[0]+2, c[1]+sz[1]/2-WALL-1, 24]) rotate([-90,0,0]) cylinder(d=7, h=WALL+2);      // camera window
        translate([c[0]+2, c[1]+sz[1]/2-WALL-2.6, 24]) rotate([-90,0,0]) cylinder(d=10, h=2.7);      // barrel relief inside
        translate([c[0]-9, c[1]+sz[1]/2-WALL-1, 30]) rotate([-90,0,0]) cylinder(d=3.2, h=WALL+2);    // status LED
    }
}
module front_solid() {
    difference() { union() { rims(); bar(); nose_pads(); for (s=[-1,1]) union() { pod_shell(s); hinge_knuckles(s); } }
                   hood_cavity(); for (s=[-1,1]) pod_cavity(s);
                   translate([-66, -0.1, GROOVE_Z]) cube([HOOD_X0+66+1, GROOVE[1]+0.1, GROOVE[0]]); }   // wire groove
    difference() { hood_shell(); hood_cavity(); }
    hood_holders();
    for (s=[-1,1]) pod_holders(s);
}
module front() difference() { front_solid(); hood_cuts(); for (s=[-1,1]) pod_cuts(s); }

// ================================================================== LIDS ====
module lid_generic(x0, y0, w, d, z, pts) difference() {
    rboxc([x0+CLR/2, y0+CLR/2, z], [w-CLR, d-CLR, LID_T], 1);
    for (p=pts) translate([p[0], p[1], z-1]) clr(LID_T+2);
}
module lid_hood() lid_generic(HOOD_X0+WALL, WALL, HOOD_X1-HOOD_X0-2*WALL, HOOD_Y1-2*WALL, HOOD_Z1, hood_boss_pts());
module lid_pod(s) { c = pod_c(s); sz = pod_sz(s); zt = POD_Z0+sz[2];
    difference() {
        lid_generic(c[0]-sz[0]/2+WALL, c[1]-sz[1]/2+BACK_W, sz[0]-2*WALL, sz[1]-WALL-BACK_W, zt, pod_boss_pts(s));
        if (s>0) translate([c[0], c[1]-6, zt-1]) cylinder(d=4.2, h=LID_T+2);                              // button actuator hole
        if (s<0) translate([c[0]-3.25, c[1]+sz[1]/2-WALL-XIAO[2]-1+ (XIAO[2]-4.5)/2, zt-1]) cube([10.5, 4.5, LID_T+2]); // USB-C (verify on the board)
    }
    if (s>0) translate([c[0]-4.4, c[1]-6-4.4, zt-BTN[2]-1.2]) difference() { cube([8.8, 8.8, BTN[2]+1.2]); translate([1.2, 1.2, -1]) cube([6.4, 6.4, BTN[2]+3]); }  // button cage
}

// =============================================================== TEMPLES ====
function bez(p0,p1,p2,p3,t) = pow(1-t,3)*p0 + 3*pow(1-t,2)*t*p1 + 3*(1-t)*t*t*p2 + pow(t,3)*p3;
module temple(s) {
    hx = hinge_x(s); hy = hinge_y(s); zk0 = HK_Z0+HK_BOT+HK_GAP;
    difference() {
        union() {
            translate([hx, hy, 0]) rotate([0,0,s*TEMPLE_SPLAY]) translate([-hx, -hy, 0]) temple_body(s, zk0);
            translate([hx, hy, zk0]) cylinder(r1=HK_R-0.5, r2=HK_R, h=0.5);
            translate([hx, hy, zk0+0.5]) cylinder(r=HK_R, h=HK_TEMPLE-1);
            translate([hx, hy, zk0+HK_TEMPLE-0.5]) cylinder(r1=HK_R, r2=HK_R-0.5, h=0.5);
        }
        translate([hx, hy, HK_Z0-1]) clr(HK_BOT+HK_TEMPLE+2*HK_GAP+HK_TOP+3);   // bore cut LAST through everything
    }
}
module temple_body(s, zk0) {
    hx = hinge_x(s); hy = hinge_y(s); zk = zk0 + HK_TEMPLE/2;
    p0 = [0, -6, 0]; p1 = [0, -TEMPLE_L-8, 0]; p2 = [0, -TEMPLE_L-24, -4]; p3 = [0, -TEMPLE_L-36, -EAR_DROP-6];
    N = 28;
    difference() {
        union() {
            hull() { translate([hx, hy, zk0]) cylinder(r=HK_R, h=HK_TEMPLE); translate([hx, hy-8, zk]) scale([TEMPLE_W/2, 4, TEMPLE_H/2]) sphere(r=1, $fn=24); }
            for (i=[0:N-1]) hull() for (t=[i/N, (i+1)/N]) { q = bez(p0,p1,p2,p3,t); k = 1 - 0.42*t; translate([hx, hy+q[1], zk+q[2]]) scale([TEMPLE_W/2*k, 4, TEMPLE_H/2*k]) sphere(r=1, $fn=24); }
            if (s>0) translate([hx-TEMPLE_W/2-1, hy-TEMPLE_L+16, zk-1]) rotate([0,90,0]) cylinder(d=SPK_D+4, h=7.5);   // speaker boss, head side
        }
        translate([hx-1.5, hy-TEMPLE_L+10, zk-1.5]) cube([3, TEMPLE_L-10+4, 3]);   // wire channel, exits on the root face
        if (s>0) { cy = hy-TEMPLE_L+16;
            translate([hx-TEMPLE_W/2-0.2, cy, zk-1]) rotate([0,90,0]) cylinder(d=SPK_D+2*CLR, h=SPK_T+CLR+0.8);   // pocket, 0.8 mm grille face toward the head
            for (a=[0:45:315]) translate([hx-TEMPLE_W/2-2, cy+6*cos(a), zk-1+6*sin(a)]) rotate([0,90,0]) cylinder(d=1.6, h=4);
            translate([hx-TEMPLE_W/2-2, cy, zk-1]) rotate([0,90,0]) cylinder(d=1.6, h=4);
        }
    }
}

// ================================================================ GHOSTS ====
module ghosts() {
    color("blue", 0.7)   translate([OLED_X, AX_Y-OLED_PCB[0]/2, BEAM_Z-OLED_PCB[1]/2]) cube([OLED_PCB[2], OLED_PCB[0], OLED_PCB[1]]);
    color("silver", 0.9) translate(MIR_C) rotate([0,-45,0]) cube([MIR[2], MIR[0], MIR[1]], center=true);
    color("cyan", 0.5)   translate([EX, AX_Y, LENS_Z]) cylinder(d=LENS_D, h=LENS_T, center=true);
    color("cyan", 0.4)   translate(COMB) rotate([-45,0,0]) cube([BS[0], BS[2], BS[1]], center=true);
    color("yellow", 0.3) translate([EX, AX_Y-5.45, BEAM_Z-10.85]) cube([OLED_X-EX, 10.9, 21.7]);
    color("yellow", 0.3) translate([EX-10.85, AX_Y-5.45, 0]) cube([21.7, 10.9, BEAM_Z]);
    color("yellow", 0.3) translate([EX-10.85, -VD, -5.45]) cube([21.7, AX_Y+VD, 10.9]);
    c = pod_c(1);
    color("red", 0.7)  translate([c[0]+POD_R[0]/2-WALL-AMP[2]-CLR, c[1]-AMP[0]/2, POD_Z0+WALL+0.4]) cube([AMP[2], AMP[0], AMP[1]]);
    color("gray", 0.7) translate([c[0]-3, c[1]-6-3, POD_Z0+POD_R[2]-BTN[2]-1.2]) cube([6, 6, BTN[2]]);
    l = pod_c(-1);
    color("orange", 0.7) translate([l[0]-POD_L[0]/2+WALL+0.4, l[1]-BAT[0]/2, POD_Z0+WALL]) cube([BAT[2], BAT[0], BAT[1]]);
    color("green", 0.6)  translate([l[0]+2-XIAO[0]/2, l[1]+POD_L[1]/2-WALL-XIAO[2]-0.4, POD_Z0+WALL+4]) cube([XIAO[0], XIAO[2], XIAO[1]]);
    hx = hinge_x(1); hy = hinge_y(1);
    translate([hx, hy, 0]) rotate([0,0,TEMPLE_SPLAY]) translate([-hx, -hy, 0])
        color("gray", 0.7) translate([hx-TEMPLE_W/2, hy-TEMPLE_L+16, HK_Z0+HK_BOT+HK_GAP+HK_TEMPLE/2-1]) rotate([0,90,0]) cylinder(d=SPK_D, h=SPK_T);
}
module head_ghost() %translate([0, -VD, 0]) import(head_file);

// ================================================================ OUTPUT ====
module assembly() {
    color("dimgray") front();
    color("darkslategray") { lid_hood(); lid_pod(1); lid_pod(-1); }
    color("dimgray") { temple(1); temple(-1); }
    if (show_parts) ghosts();
    if (show_head) head_ghost();
}
if (part == "front") front();
else if (part == "lid_hood") lid_hood();
else if (part == "lid_r") lid_pod(1);
else if (part == "lid_l") lid_pod(-1);
else if (part == "temple_r") temple(1);
else if (part == "temple_l") temple(-1);
else if (part == "fit") { %front(); ghosts(); }
else if (part == "layout") { %front(); ghosts(); }
else if (part == "exploded") { color("dimgray") front(); color("darkslategray") translate([0,0,18]) { lid_hood(); lid_pod(1); lid_pod(-1); } for (s=[-1,1]) color("dimgray") translate([s*12, -28, 0]) temple(s); }
else assembly();
