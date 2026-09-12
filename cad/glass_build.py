"""Gzowo Glass — parametric concept model, renders and turntable.

Run headless:
  Blender -b -P cad/glass_build.py -- stills          # product + on-head stills
  Blender -b -P cad/glass_build.py -- turntable       # 360° mp4
  Blender -b -P cad/glass_build.py -- save            # write cad/glass.blend

Units: 1 Blender unit = 1 mm. Frame of reference: origin between the eyes on
the cornea plane is at y = -16; X right, Y forward (away from the face), Z up.

Layout decisions (see ../RESEARCH.md for why):
  * chunky wayfarer front, tinted lenses in both eyes
  * two symmetric "pods" at the hinges (Ray-Ban Meta style):
      right pod  = XIAO ESP32-S3 Sense + camera + 0.96" OLED (screen facing forward)
      left pod   = LiPo battery as counterweight
  * brow block over the right lens hides the fold mirror + lens (f = 50 mm)
  * combiner (beam splitter) hangs from the brow block into the upper part of
    the right lens, 45° about Z, >= 20 mm from the cornea
  * speaker in the right temple next to the ear, button on top of the right pod,
    USB-C on the outer face of the right pod
"""
import bpy, bmesh, math, os, sys
from mathutils import Vector, Euler

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.normpath(os.path.join(HERE, '..', 'renders'))
os.makedirs(OUT, exist_ok=True)

# ----------------------------------------------------------------- helpers ---
def mat(name, color, rough=0.5, metallic=0.0, alpha=1.0, emit=None, emit_strength=0.0):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    bsdf = m.node_tree.nodes['Principled BSDF']
    bsdf.inputs['Base Color'].default_value = (*color, 1)
    bsdf.inputs['Roughness'].default_value = rough
    bsdf.inputs['Metallic'].default_value = metallic
    bsdf.inputs['Alpha'].default_value = alpha
    if emit:
        bsdf.inputs['Emission Color'].default_value = (*emit, 1)
        bsdf.inputs['Emission Strength'].default_value = emit_strength
    if alpha < 1:
        m.surface_render_method = 'BLENDED'
        m.use_transparency_overlap = True
    return m

def bevel(obj, width=1.5, segs=4):
    b = obj.modifiers.new('bevel', 'BEVEL')
    b.width = width; b.segments = segs; b.limit_method = 'ANGLE'
    for p in obj.data.polygons: p.use_smooth = True
    return obj

def box(name, center, size, m, bev=1.5, rot=(0, 0, 0), parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=center, rotation=rot)
    o = bpy.context.object; o.name = name; o.scale = size
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(m)
    if bev: bevel(o, bev)
    if parent: o.parent = parent
    return o

def cyl(name, center, r, depth, m, axis='Z', parent=None, verts=48):
    rot = {'Z': (0, 0, 0), 'Y': (math.pi / 2, 0, 0), 'X': (0, math.pi / 2, 0)}[axis]
    bpy.ops.mesh.primitive_cylinder_add(vertices=verts, radius=r, depth=depth, location=center, rotation=rot)
    o = bpy.context.object; o.name = name; o.data.materials.append(m)
    for p in o.data.polygons: p.use_smooth = True
    if parent: o.parent = parent
    return o

def ellipsoid(name, center, radii, m, parent=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=64, ring_count=32, radius=1, location=center)
    o = bpy.context.object; o.name = name; o.scale = radii
    bpy.ops.object.transform_apply(scale=True)
    o.data.materials.append(m)
    for p in o.data.polygons: p.use_smooth = True
    sub = o.modifiers.new('sub', 'SUBSURF'); sub.levels = 1; sub.render_levels = 2
    if parent: o.parent = parent
    return o

def chaikin(pts, it=3):
    for _ in range(it):
        out = []
        n = len(pts)
        for i in range(n):
            p, q = Vector(pts[i]), Vector(pts[(i + 1) % n])
            out.append(tuple(p * 0.75 + q * 0.25)); out.append(tuple(p * 0.25 + q * 0.75))
        pts = out
    return pts

def extrude_outline(name, pts_xz, y0, y1, m, mirror=False, parent=None):
    """Extrude a closed 2-D outline (x, z) along Y into a solid."""
    bm = bmesh.new()
    sx = -1 if mirror else 1
    bottom = [bm.verts.new((sx * x, y0, z)) for x, z in pts_xz]
    bm.faces.new(bottom)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    r = bmesh.ops.extrude_face_region(bm, geom=bm.faces[:])
    vs = [g for g in r['geom'] if isinstance(g, bmesh.types.BMVert)]
    bmesh.ops.translate(bm, verts=vs, vec=(0, y1 - y0, 0))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    me = bpy.data.meshes.new(name); bm.to_mesh(me); bm.free()
    o = bpy.data.objects.new(name, me); bpy.context.collection.objects.link(o)
    o.data.materials.append(m)
    if parent: o.parent = parent
    return o

def boolean_cut(obj, cutter):
    b = obj.modifiers.new('cut', 'BOOLEAN'); b.operation = 'DIFFERENCE'; b.object = cutter
    b.solver = 'EXACT'
    cutter.hide_render = True; cutter.hide_viewport = True

# ---------------------------------------------------------------- materials ---
def make_materials():
    g = globals()
    g['M_FRAME'] = mat('frame', (0.02, 0.02, 0.022), rough=0.42)
    g['M_FRAME2'] = mat('frame_soft', (0.035, 0.035, 0.038), rough=0.6)
    g['M_LENS'] = mat('lens', (0.03, 0.035, 0.045), rough=0.08, alpha=0.78); g['M_LENS'].surface_render_method = 'DITHERED'
    g['M_COMB'] = mat('combiner', (0.6, 0.75, 0.9), rough=0.03, alpha=0.2)
    g['M_HUD'] = mat('hud', (0.1, 0.5, 1.0), emit=(0.25, 0.65, 1.0), emit_strength=18)
    g['M_LED'] = mat('led', (0.2, 0.9, 1.0), emit=(0.2, 0.9, 1.0), emit_strength=25)
    g['M_METAL'] = mat('metal', (0.6, 0.6, 0.62), rough=0.3, metallic=1.0)
    g['M_CAM'] = mat('camlens', (0.01, 0.01, 0.02), rough=0.05)
    g['M_HEAD'] = mat('head', (0.72, 0.7, 0.68), rough=0.65)
    g['M_FLOOR'] = mat('floor', (0.82, 0.82, 0.82), rough=0.9)

# ------------------------------------------------------------------- scene ---
def reset():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    sc.unit_settings.system = 'METRIC'; sc.unit_settings.scale_length = 0.001
    sc.render.engine = 'BLENDER_EEVEE_NEXT'
    sc.eevee.taa_render_samples = 128
    sc.eevee.use_raytracing = True
    sc.eevee.use_shadows = True
    sc.render.film_transparent = False
    w = bpy.data.worlds.new('world'); sc.world = w; w.use_nodes = True
    w.node_tree.nodes['Background'].inputs[0].default_value = (0.86, 0.86, 0.87, 1)
    w.node_tree.nodes['Background'].inputs[1].default_value = 1.0
    make_materials()
    return sc

def lights():
    for name, rot, e, ang in [('key', (0.95, 0.15, 0.7), 3.2, 8), ('fill', (1.1, -0.3, -1.6), 1.1, 20), ('rim', (0.5, 0.2, 2.6), 2.0, 5)]:
        bpy.ops.object.light_add(type='SUN', rotation=rot)
        l = bpy.context.object; l.name = name; l.data.energy = e; l.data.angle = math.radians(ang)

# ----------------------------------------------------------------- glasses ---
# Geometry comes from glass.scad (exported by export-all.sh into cad/stl/).
# Numbers below mirror the SCAD layout so lenses/optics land in the same place.
STL = os.path.join(HERE, 'stl')
EX = 31.5                                   # PD/2
LENS_IN = [(6, 6), (50, 6), (52, -2), (48, -14), (40, -20), (20, -21), (9, -17), (5, -6)]
COMB = (EX, 16, 0)                          # beam splitter centre (SCAD: COMB), in the unwrapped right frame; plate tilted 45° about X
WRAP = math.radians(6)                      # SCAD: WRAP — each half rotated about Z at the bridge

def wrap(p, side=1):
    """Rotate a point of the right (side=1) / left (side=-1) half about Z by -side*WRAP (as glass.scad does)."""
    a = -side * WRAP
    x, y, z = p
    return (x * math.cos(a) - y * math.sin(a), x * math.sin(a) + y * math.cos(a), z)

def import_stl(name, m, parent):
    bpy.ops.wm.stl_import(filepath=os.path.join(STL, name + '.stl'))
    o = bpy.context.selected_objects[0]; o.name = name
    o.data.materials.append(m)
    try:
        bpy.ops.object.shade_auto_smooth(angle=math.radians(35))
    except Exception:
        for p in o.data.polygons: p.use_smooth = True
    o.parent = parent
    return o

def outline_mesh(name, pts, y0, y1, m, mirror, parent):
    return extrude_outline(name, chaikin(pts, 2), y0, y1, m, mirror, parent)

def build_glasses():
    root = bpy.data.objects.new('GLASS', None); bpy.context.collection.objects.link(root)
    for n in ('front', 'temple_r', 'temple_l'):
        import_stl(n, M_FRAME, root)
    for n in ('lid_r', 'lid_l'):
        import_stl(n, M_FRAME2, root)
    # tinted lenses sit in the 2.4 mm rebate at the back of the rims
    for side, mirror in (('R', False), ('L', True)):
        outline_mesh(f'lens_{side}', LENS_IN, 0.4, 2.4, M_LENS, mirror, root)
    # beam splitter hanging below the hood, 45 deg about Z
    comb = box('combiner', wrap(COMB), (30, 1.6, 30), M_COMB, 0.2, rot=(math.radians(-45), 0, -WRAP), parent=root)
    # HUD content on the eye side of the plate (upper part, where the beam lands)
    bpy.ops.object.text_add(location=wrap((COMB[0], COMB[1] - 0.6, COMB[2] + 0.6))); t = bpy.context.object; t.name = 'hud_text'
    t.data.body = '12:34\nGLASS'; t.data.size = 4; t.data.align_x = 'CENTER'; t.data.align_y = 'CENTER'
    t.data.extrude = 0.1; t.data.materials.append(M_HUD)
    t.rotation_euler = Euler((math.radians(45), 0, math.radians(180) - WRAP), 'XYZ')
    t.location = Vector(wrap((COMB[0], COMB[1] - 0.6, COMB[2] + 0.6)))
    t.parent = root
    # camera lens glass in the right pod's front wall, status LED on the left pod
    cyl('cam_glass', wrap((88, 27.3, 31)), 2.8, 0.6, M_CAM, 'Y', root); bpy.context.object.rotation_euler.z = -WRAP
    cyl('button_cap', wrap((78, -8, 38.3)), 3.4, 1.2, M_FRAME2, 'Z', root)
    cyl('led', wrap((-88, 27.3, 31), -1), 1.3, 0.6, M_LED, 'Y', root); bpy.context.object.rotation_euler.z = WRAP
    return root

# --------------------------------------------------------------- mannequin ---
def build_head():
    root = bpy.data.objects.new('HEAD', None); bpy.context.collection.objects.link(root)
    ellipsoid('cranium', (0, -100, 15), (76, 95, 100), M_HEAD, root)
    ellipsoid('jaw', (0, -85, -70), (62, 75, 70), M_HEAD, root)
    ellipsoid('nose', (0, -10, -18), (11, 20, 24), M_HEAD, root)
    for sx in (1, -1):
        ellipsoid(f'ear_{sx}', (sx * 77, -95, -12), (5, 16, 24), M_HEAD, root)
        ellipsoid(f'eye_{sx}', (sx * 32, -18, 0), (13, 13, 13), M_HEAD, root)
        ellipsoid(f'brow_{sx}', (sx * 32, -12, 22), (24, 10, 6), M_HEAD, root)
    cyl('neck', (0, -95, -150), 44, 130, M_HEAD, 'Z', root)
    ellipsoid('shoulders', (0, -110, -235), (200, 110, 55), M_HEAD, root)
    return root

# ------------------------------------------------------------- scan head ---
VD = 18.0   # must match VD in glass.scad

def build_scan_head():
    """Append Jurek's textured scan (reference/head-mm.blend, cornea plane at y=0) and place it at y = -VD."""
    path = os.path.join(HERE, '..', 'reference', 'head2-mm.blend')   # full head with ears (textured)
    with bpy.data.libraries.load(path, link=False) as (src, dst):
        dst.objects = [n for n in src.objects]
    root = bpy.data.objects.new('HEAD', None); bpy.context.collection.objects.link(root)
    for ob in dst.objects:
        if ob is None or ob.type != 'MESH': continue
        bpy.context.collection.objects.link(ob)
        ob.location = (0, -VD, 0); ob.parent = root
        for m in ob.data.materials:
            m.use_backface_culling = True
            if os.environ.get('GLASS_XRAY'):
                m.surface_render_method = 'BLENDED'; m.node_tree.nodes['Principled BSDF'].inputs['Alpha'].default_value = 0.45
    return root

# ----------------------------------------------------------------- cameras ---
def camera(loc, target, lens=85, name='cam'):
    bpy.ops.object.camera_add(location=loc); c = bpy.context.object; c.name = name
    c.data.lens = lens; c.data.clip_end = 20000
    c.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat('-Z', 'Y').to_euler()
    bpy.context.scene.camera = c
    return c

def render(path, w=1600, h=1000):
    sc = bpy.context.scene
    sc.render.resolution_x = w; sc.render.resolution_y = h; sc.render.resolution_percentage = 100
    sc.render.image_settings.file_format = 'PNG'
    sc.render.filepath = path
    bpy.ops.render.render(write_still=True)
    print('RENDERED', path)

def stills(scan=False):
    sc = reset(); lights()
    g = build_glasses()
    head = build_scan_head() if scan else build_head()
    # on-head shots
    tag = 'scan' if scan else 'head'
    camera((380, 480, 120), (10, -40, 0), 85, 'cam_head34'); render(os.path.join(OUT, f'glass-{tag}-front34.png'))
    camera((620, -80, 60), (0, -70, 0), 85, 'cam_side'); render(os.path.join(OUT, f'glass-{tag}-side.png'))
    camera((40, 640, 60), (0, -40, 0), 85, 'cam_front'); render(os.path.join(OUT, f'glass-{tag}-front.png'))
    if scan:
        if os.environ.get('GLASS_XRAY'):
            camera((620, -80, 60), (0, -70, 0), 85, 'cam_side_x'); render(os.path.join(OUT, 'glass-scan-side-xray.png'))
            camera((0, -60, 700), (0, -60, 0), 85, 'cam_top_x'); render(os.path.join(OUT, 'glass-scan-top-xray.png'))
        return
    # product shots without the head
    head.hide_render = True
    for o in head.children: o.hide_render = True
    bpy.ops.mesh.primitive_plane_add(size=3000, location=(0, -60, -30)); fl = bpy.context.object; fl.data.materials.append(M_FLOOR)
    camera((300, 330, 170), (10, -30, 10), 85, 'cam_prod34'); render(os.path.join(OUT, 'glass-product-front34.png'))
    camera((0, -60, 700), (0, -60, 0), 85, 'cam_top'); render(os.path.join(OUT, 'glass-product-top.png'))
    camera((190, 120, 90), (50, 10, 18), 100, 'cam_pod'); render(os.path.join(OUT, 'glass-detail-pod.png'))
    camera((-300, 330, 170), (-10, -30, 10), 85, 'cam_prod34L'); render(os.path.join(OUT, 'glass-product-front34-left.png'))

def turntable(frames=120):
    sc = reset(); lights()
    g = build_glasses()
    bpy.ops.mesh.primitive_plane_add(size=3000, location=(0, -60, -30)); fl = bpy.context.object; fl.data.materials.append(M_FLOOR)
    # rotate the glasses around their own centre (y ~ -55)
    pivot = bpy.data.objects.new('pivot', None); bpy.context.collection.objects.link(pivot)
    pivot.location = (0, -55, 0); g.parent = pivot; g.location = (0, 55, 0)
    pivot.rotation_euler = (0, 0, 0); pivot.keyframe_insert('rotation_euler', frame=1)
    pivot.rotation_euler = (0, 0, math.tau); pivot.keyframe_insert('rotation_euler', frame=frames + 1)
    for fc in pivot.animation_data.action.fcurves:
        for kp in fc.keyframe_points: kp.interpolation = 'LINEAR'
    camera((0, 380, 150), (0, -55, 5), 85, 'cam_turn')
    sc.frame_start = 1; sc.frame_end = frames
    sc.render.resolution_x = 1280; sc.render.resolution_y = 800; sc.render.fps = 30
    sc.eevee.taa_render_samples = 32
    sc.render.image_settings.file_format = 'FFMPEG'
    sc.render.ffmpeg.format = 'MPEG4'; sc.render.ffmpeg.codec = 'H264'; sc.render.ffmpeg.constant_rate_factor = 'HIGH'
    sc.render.filepath = os.path.join(OUT, 'glass-turntable.mp4')
    bpy.ops.render.render(animation=True)
    print('RENDERED turntable')

def frames(n=96, w=1600, h=1000, out=None):
    """Turntable as a PNG frame sequence for the website scroll-scrubber (white studio, no head)."""
    sc = reset(); lights()
    w_bg = sc.world.node_tree.nodes['Background']; w_bg.inputs[0].default_value = (1, 1, 1, 1)
    sc.render.film_transparent = True
    g = build_glasses()
    pivot = bpy.data.objects.new('pivot', None); bpy.context.collection.objects.link(pivot)
    pivot.location = (0, -55, 0); g.parent = pivot; g.location = (0, 55, 0)
    camera((0, 420, 140), (0, -55, 5), 85, 'cam_turn')
    sc.render.resolution_x = w; sc.render.resolution_y = h; sc.eevee.taa_render_samples = 48
    sc.render.image_settings.file_format = 'PNG'; sc.render.image_settings.color_mode = 'RGBA'
    out = out or os.path.join(OUT, 'frames'); os.makedirs(out, exist_ok=True)
    for i in range(n):
        pivot.rotation_euler = (0, 0, math.tau * i / n)
        sc.render.filepath = os.path.join(out, f'f{i:03d}.png')
        bpy.ops.render.render(write_still=True)
    print('RENDERED frames', n)

def site_stills():
    """Hero + detail shots for the website: white studio, mannequin optional, transparent background."""
    sc = reset(); lights()
    sc.world.node_tree.nodes['Background'].inputs[0].default_value = (1, 1, 1, 1)
    sc.render.film_transparent = True
    g = build_glasses()
    camera((300, 330, 170), (10, -30, 10), 85, 'cam_hero'); render(os.path.join(OUT, 'site-hero.png'), 2400, 1500)
    camera((60, 560, 40), (0, -20, 10), 85, 'cam_front'); render(os.path.join(OUT, 'site-front.png'), 2400, 1500)
    camera((190, 120, 90), (50, 10, 18), 100, 'cam_pod'); render(os.path.join(OUT, 'site-pod.png'), 2400, 1500)
    camera((90, 160, 40), (31, 10, 5), 120, 'cam_eye'); render(os.path.join(OUT, 'site-eye.png'), 2400, 1500)
    camera((-300, 330, 170), (-10, -30, 10), 85, 'cam_left'); render(os.path.join(OUT, 'site-left.png'), 2400, 1500)
    # mannequin shot (neutral head, never the scan)
    head = build_head()
    camera((330, 420, 80), (10, -20, 10), 85, 'cam_head34'); render(os.path.join(OUT, 'site-head.png'), 2400, 1500)

def glb():
    sc = reset(); build_glasses()
    for o in bpy.data.objects:
        if o.type == 'MESH' and o.name.startswith(('lens_', 'combiner', 'hud_text')): o.data.materials[0].blend_method = 'BLEND'
    path = os.path.join(OUT, 'glass.glb')
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', export_apply=True, export_draco_mesh_compression_enable=False)
    print('EXPORTED', path)

def save():
    sc = reset(); lights(); build_glasses(); build_head()
    bpy.ops.wm.save_as_mainfile(filepath=os.path.join(HERE, 'glass.blend'))

if __name__ == '__main__':
    args = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else ['stills']
    {'stills': stills, 'scan': lambda: stills(scan=True), 'turntable': turntable, 'frames': frames, 'site': site_stills, 'glb': glb, 'save': save}[args[0]]()
