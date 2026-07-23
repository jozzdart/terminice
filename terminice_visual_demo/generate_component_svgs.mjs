import { mkdir, readFile, writeFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import vm from "node:vm";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const repoRoot = resolve(here, "..");
const framesPath = resolve(here, "frames.js");
const readmePath = resolve(repoRoot, "terminice", "README.md");
const assetsDir = resolve(
  repoRoot,
  "terminice",
  "assets",
  "component_showcases",
);

const themes = ["fire", "matrix", "arcane"];
const headingOverrides = {
  customComponents: /^## Custom Components & Extensibility$/,
  messagePrimitives: /^### Message Primitives - Small Status Lines$/,
};

const updateReadme = !process.argv.includes("--assets-only");

const frames = await loadFrames();
const components = uniqueComponents(frames);
const framesByKey = new Map(
  frames.map((frame) => [`${frame.id}|${frame.theme}`, frame]),
);

await mkdir(assetsDir, { recursive: true });

const generated = [];
for (const component of components) {
  const svg = renderComponentSvg(component, framesByKey);
  const filename = `${component.id}.svg`;
  await writeFile(resolve(assetsDir, filename), svg);
  generated.push(component.id);
}

let readmeReport = null;
if (updateReadme) {
  readmeReport = await updateReadmeVisuals(generated);
}

console.log(
  JSON.stringify(
    {
      generated: generated.length,
      themes,
      output: "terminice/assets/component_showcases",
      readme: readmeReport,
    },
    null,
    2,
  ),
);

async function loadFrames() {
  const source = await readFile(framesPath, "utf8");
  const context = {};
  context.globalThis = context;
  vm.runInNewContext(source, context, { filename: framesPath });

  if (!Array.isArray(context.TERMINICE_REAL_FRAMES)) {
    throw new Error("frames.js did not expose TERMINICE_REAL_FRAMES");
  }

  return context.TERMINICE_REAL_FRAMES;
}

function uniqueComponents(sourceFrames) {
  const seen = new Set();
  const result = [];

  for (const frame of sourceFrames) {
    if (seen.has(frame.id)) continue;
    seen.add(frame.id);
    result.push({
      id: frame.id,
      group: frame.group,
      summary: frame.summary,
    });
  }

  return result;
}

function renderComponentSvg(component, framesByKey) {
  const cells = themes.map((theme) => {
    const frame = framesByKey.get(`${component.id}|${theme}`);
    return {
      theme,
      frame,
      lines: frame ? parseTerminalHtml(frame.html) : [[]],
      plainLines: frame ? frame.plainText.split("\n") : ["Missing frame"],
    };
  });

  const fontSize = 11.5;
  const lineHeight = 14.5;
  const charWidth = 7.25;
  const padX = 16;
  const padY = 16;
  const minColumnWidth = 300;
  const maxChars = Math.max(
    1,
    ...cells.flatMap((cell) =>
      cell.plainLines.map((line) => Array.from(line).length),
    ),
  );
  const maxLines = Math.max(1, ...cells.map((cell) => cell.lines.length));
  const columnWidth = Math.ceil(
    Math.max(minColumnWidth, maxChars * charWidth + padX * 2),
  );
  const width = columnWidth * themes.length;
  const bodyHeight = maxLines * lineHeight + padY * 2;
  const height = bodyHeight;

  const parts = [
    '<svg xmlns="http://www.w3.org/2000/svg"',
    `  width="${width}" height="${height}" viewBox="0 0 ${width} ${height}"`,
    '  role="img" aria-labelledby="title desc">',
    `  <title id="title">${escapeXml(component.id)} in fire, matrix, and arcane themes</title>`,
    `  <desc id="desc">${escapeXml(component.summary)}</desc>`,
    `  <rect width="${width}" height="${height}" fill="#05070c"/>`,
  ];

  cells.forEach((cell, index) => {
    const x = index * columnWidth;
    const panelFill = index % 2 === 0 ? "#080d16" : "#0b111d";
    parts.push(
      `  <rect x="${x}" y="0" width="${columnWidth}" height="${height}" fill="${panelFill}"/>`,
    );

    if (index > 0) {
      parts.push(
        `  <line x1="${x}" y1="0" x2="${x}" y2="${height}" stroke="#ffffff" stroke-opacity="0.14"/>`,
      );
    }

    parts.push(renderTerminalLines(cell.lines, x + padX, padY, {
      fontSize,
      lineHeight,
      charWidth,
    }));
  });

  parts.push("</svg>");
  return `${parts.join("\n")}\n`;
}

function parseTerminalHtml(html) {
  const body = html
    .replace(/^<pre\b[^>]*>/, "")
    .replace(/<\/pre>$/, "");
  const tokenPattern = /<span\s+style="([^"]*)">([\s\S]*?)<\/span>/g;
  const lines = [[]];
  let lastIndex = 0;
  let match;

  while ((match = tokenPattern.exec(body)) !== null) {
    appendRun(lines, body.slice(lastIndex, match.index), defaultStyle());
    appendRun(lines, match[2], styleFromSpan(match[1]));
    lastIndex = tokenPattern.lastIndex;
  }

  appendRun(lines, body.slice(lastIndex), defaultStyle());
  return lines;
}

function appendRun(lines, rawText, style) {
  if (!rawText) return;
  const parts = decodeHtml(rawText).split("\n");

  parts.forEach((part, index) => {
    if (index > 0) lines.push([]);
    if (part.length > 0) {
      lines[lines.length - 1].push({ text: part, ...style });
    }
  });
}

function defaultStyle() {
  return { fill: "#eef4ff", weight: "400", background: null, opacity: "1" };
}

function styleFromSpan(style) {
  return {
    fill: style.match(/color:\s*([^;]+)/)?.[1] || "#eef4ff",
    weight: style.match(/font-weight:\s*([^;]+)/)?.[1] || "400",
    background: style.match(/background-color:\s*([^;]+)/)?.[1] || null,
    opacity: style.match(/opacity:\s*([^;]+)/)?.[1] || "1",
  };
}

function renderTerminalLines(lines, x, y, options) {
  const output = [
    `  <g font-family="${fontFamily()}" font-size="${options.fontSize}" font-variant-ligatures="none" xml:space="preserve">`,
  ];

  lines.forEach((line, lineIndex) => {
    let column = 0;
    for (const run of line) {
      for (const char of Array.from(run.text)) {
        const runX = x + column * options.charWidth;
        const runY = y + lineIndex * options.lineHeight;
        if (run.background) {
          output.push(
            `    <rect x="${round(runX)}" y="${round(runY)}" width="${round(options.charWidth)}" height="${round(options.lineHeight)}" ${svgFillAttributes(run.background)}${svgOpacityAttribute(run.opacity)}/>`,
          );
        }
        if (char !== " ") {
          output.push(
            `    <text x="${round(runX)}" y="${round(runY + options.fontSize)}" fill="${escapeXml(run.fill)}" font-weight="${escapeXml(run.weight)}"${svgOpacityAttribute(run.opacity)}>${escapeXml(char)}</text>`,
          );
        }
        column += 1;
      }
    }
  });

  output.push("  </g>");
  return output.join("\n");
}

function svgFillAttributes(color) {
  const rgba = String(color).match(
    /^rgba\((\d+),\s*(\d+),\s*(\d+),\s*([0-9.]+)\)$/,
  );
  if (!rgba) return `fill="${escapeXml(color)}" `;

  const [, red, green, blue, alpha] = rgba;
  const hex = [red, green, blue]
    .map((channel) => Number(channel).toString(16).padStart(2, "0"))
    .join("");
  return `fill="#${hex}" fill-opacity="${escapeXml(alpha)}" `;
}

function svgOpacityAttribute(opacity) {
  return opacity && opacity !== "1" ? ` opacity="${escapeXml(opacity)}"` : "";
}

async function updateReadmeVisuals(componentIds) {
  const source = await readFile(readmePath, "utf8");
  let lines = source.split("\n");
  const inserted = [];
  const missing = [];

  for (const componentId of componentIds) {
    lines = replaceExistingBlock(lines, componentId);
    const headingIndex = findHeadingIndex(lines, componentId);

    if (headingIndex === -1) {
      missing.push(componentId);
      continue;
    }

    lines = insertBlockAfterIntro(lines, headingIndex, componentId);
    inserted.push(componentId);
  }

  await writeFile(readmePath, lines.join("\n"));
  return { inserted: inserted.length, missing };
}

function replaceExistingBlock(lines, componentId) {
  const start = `<!-- terminice-visual:start:${componentId} -->`;
  const end = `<!-- terminice-visual:end:${componentId} -->`;
  const startIndex = lines.indexOf(start);
  if (startIndex === -1) return lines;

  const endIndex = lines.indexOf(end);
  if (endIndex === -1 || endIndex < startIndex) {
    throw new Error(`Broken visual marker block for ${componentId}`);
  }

  const nextLines = [...lines];
  nextLines.splice(startIndex, endIndex - startIndex + 1);
  return nextLines;
}

function findHeadingIndex(lines, componentId) {
  const override = headingOverrides[componentId];
  if (override) return lines.findIndex((line) => override.test(line));

  return lines.findIndex((line) =>
    new RegExp(`^### \`${escapeRegex(componentId)}\`(?:\\s|-|$)`).test(line),
  );
}

function insertBlockAfterIntro(lines, headingIndex, componentId) {
  let index = headingIndex + 1;

  while (index < lines.length && lines[index].trim() === "") index += 1;
  while (index < lines.length && lines[index].trim() !== "") index += 1;

  const nextLines = [...lines];
  const insertion = ["", ...visualBlock(componentId), ""];
  if (nextLines[index]?.trim() === "") {
    nextLines.splice(index, 1, ...insertion);
  } else {
    nextLines.splice(index, 0, ...insertion);
  }
  return nextLines;
}

function visualBlock(componentId) {
  return [
    `<!-- terminice-visual:start:${componentId} -->`,
    `<p>`,
    `  <img src="assets/component_showcases/${componentId}.svg" alt="${componentId} in fire, matrix, and arcane Terminice themes" width="1000"/>`,
    `</p>`,
    `<!-- terminice-visual:end:${componentId} -->`,
  ];
}

function decodeHtml(value) {
  return String(value)
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">")
    .replaceAll("&quot;", '"')
    .replaceAll("&#39;", "'")
    .replaceAll("&amp;", "&");
}

function escapeXml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function escapeRegex(value) {
  return String(value).replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
}

function round(value) {
  return Math.round(value * 10) / 10;
}

function fontFamily() {
  return "SFMono-Regular, 'SF Mono', 'JetBrains Mono', Menlo, Monaco, 'Cascadia Mono', 'DejaVu Sans Mono', Consolas, 'Liberation Mono', 'Courier New', monospace";
}
