// Install dependencies in work/polyhaven-tools; sources stay outside the shipped project.
import { NodeIO } from '../work/polyhaven-tools/node_modules/@gltf-transform/core/dist/index.js';
import { ALL_EXTENSIONS } from '../work/polyhaven-tools/node_modules/@gltf-transform/extensions/dist/index.js';
import { dedup, prune, weld, simplify } from '../work/polyhaven-tools/node_modules/@gltf-transform/functions/dist/index.js';
import { MeshoptSimplifier } from '../work/polyhaven-tools/node_modules/meshoptimizer/index.js';
import fs from 'node:fs/promises';
import path from 'node:path';
const io = new NodeIO().registerExtensions(ALL_EXTENSIONS);
await MeshoptSimplifier.ready;
const source = 'work/polyhaven-source';
await fs.mkdir('godot/assets/polyhaven', { recursive: true });
const counts = doc => doc.getRoot().listMeshes().reduce((sum,mesh) => sum+mesh.listPrimitives().reduce((n,p)=>n+(p.getIndices()?.getCount() || p.getAttribute('POSITION').getCount())/3,0),0);
const alphaMaterials = {
  fern_02: ['fern_02'],
  fir_sapling_medium: ['fir_sapling_medium_twigs'],
  grass_medium_01: ['grass_medium_01'],
  pine_sapling_small: ['pine_sapling_small_twig'],
  wild_rooibos_bush: ['wild_rooibos_bush_twigs','wild_rooibos_bush_leaves'],
};
const alphaImages = {
  fern_02: 'fern_02_diff_1k_rgba.png',
  fir_sapling_medium: 'fir_sapling_medium_twigs_diff_1k_rgba.png',
  grass_medium_01: 'grass_medium_01_diff_1k_rgba.png',
  pine_sapling_small: 'pine_sapling_small_twig_diff_1k_rgba.png',
  wild_rooibos_bush: 'wild_rooibos_bush_diff_1k_rgba.png',
};
for (const id of await fs.readdir(source)) {
  const target = `godot/assets/polyhaven/${id}.glb`;
  const doc = await io.read(path.join(source,id,`${id}.gltf`));
  if (alphaImages[id]) {
    const rgba = await fs.readFile(path.join(source,id,'textures',alphaImages[id]));
    for (const material of doc.getRoot().listMaterials()) {
      if (!alphaMaterials[id].includes(material.getName())) continue;
      const texture = material.getBaseColorTexture();
      texture.setImage(rgba);
      texture.setMimeType('image/png');
    }
  }
  const before = counts(doc);
  const ratio = id.includes('sapling') ? .14 : id.includes('factory') ? .8 : .4;
  await doc.transform(dedup(), weld(), simplify({simplifier:MeshoptSimplifier,ratio,error:.003}), prune());
  await io.write(target,doc);
  console.log(`${id}: ${Math.round(before)} -> ${Math.round(counts(doc))} triangles; ${(await fs.stat(target)).size/1048576|0} MB`);
}
