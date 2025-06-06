import trimesh
import numpy as np

# 创建气缸
cylinder = trimesh.creation.cylinder(radius=10, height=40, sections=32)
cylinder.apply_translation([0, 0, 20])

# 创建活塞
piston = trimesh.creation.cylinder(radius=9, height=8, sections=32)
piston.apply_translation([0, 0, 36])

# 创建曲轴
crank = trimesh.creation.cylinder(radius=3, height=60, sections=32)
crank.apply_translation([0, 0, -10])

# 创建缸体
block = trimesh.creation.box(extents=[30, 30, 10])
block.apply_translation([0, 0, 5])

# 爆炸视图：将各部件沿Z轴分离
cylinder.apply_translation([0, 0, 60])
piston.apply_translation([0, 0, 100])
crank.apply_translation([0, 0, -40])
block.apply_translation([0, 0, 20])

# 合并所有部件
engine = trimesh.util.concatenate([cylinder, piston, crank, block])

# 导出为OBJ文件
engine.export('engine_exploded.obj')
print("已生成爆炸三维模型：engine_exploded.obj")