document.addEventListener('DOMContentLoaded', () => {
    const nodes = document.querySelectorAll('.node');
    const connectors = document.querySelectorAll('.connector');

    // 简单的悬停高亮相关连接线 (示例)
    // 注意: 这种基于ID的连接方式对于复杂图谱不实用，真实场景下会基于数据来关联
    const nodeLineMap = {
        // Key: node group transform (approximate) -> Value: array of line IDs
        'translate(450, 100)': ['line-c-1a', 'line-c-1b', 'line-c-1c'], // 中心节点
        'translate(250, 225)': ['line-c-1a', 'line-1a-2a', 'line-1a-2b'], // 分支 A
        'translate(650, 225)': ['line-c-1b', 'line-1b-2c'], // 分支 B
        'translate(450, 325)': ['line-c-1c'], // 分支 C
        'translate(150, 295)': ['line-1a-2a'], // 子分支 A1
        'translate(350, 295)': ['line-1a-2b'], // 子分支 A2
        'translate(750, 295)': ['line-1b-2c'], // 子分支 B1
    };
    
    nodes.forEach(node => {
        node.addEventListener('mouseenter', () => {
            // 尝试找到与此节点相关的线
            const nodeTransform = node.getAttribute('transform');
            const relatedLineIds = nodeLineMap[nodeTransform] || [];
            
            relatedLineIds.forEach(lineId => {
                const line = document.getElementById(lineId);
                if (line) {
                    line.classList.add('highlighted');
                }
            });
        });

        node.addEventListener('mouseleave', () => {
            connectors.forEach(connector => {
                connector.classList.remove('highlighted');
            });
        });

        // 点击节点时，给节点添加一个"active"类，可以用来做更复杂的视觉效果
        node.addEventListener('click', () => {
            // 移除其他节点的active状态
            nodes.forEach(n => n.classList.remove('active-node'));
            // 给当前节点添加active状态
            node.classList.add('active-node');
            console.log(`Node clicked: ${node.querySelector('text').textContent}`);
            // 可以在这里扩展更多交互，比如聚焦、展开子节点等
        });
    });

    // 给SVG添加简单的拖拽和缩放的视觉提示 (实际功能需要更复杂的库或代码)
    const svgElement = document.getElementById('mindmap-svg');
    let isPanning = false;
    let startPoint = { x: 0, y: 0 };
    let originalViewBox = svgElement.getAttribute('viewBox').split(' ').map(Number);

    svgElement.addEventListener('mousedown', (e) => {
        if (e.target === svgElement || e.target.closest('#connections')) { // 仅在SVG背景或线上点击时触发平移
            isPanning = true;
            startPoint = { x: e.clientX, y: e.clientY };
            svgElement.style.cursor = 'grabbing';
        }
    });

    document.addEventListener('mousemove', (e) => {
        if (!isPanning) return;
        const dx = e.clientX - startPoint.x;
        const dy = e.clientY - startPoint.y;
        // 这里的系数需要根据SVG大小和缩放级别调整，0.5是一个示例值
        const newViewBoxX = originalViewBox[0] - dx * 0.5; 
        const newViewBoxY = originalViewBox[1] - dy * 0.5;
        svgElement.setAttribute('viewBox', `${newViewBoxX} ${newViewBoxY} ${originalViewBox[2]} ${originalViewBox[3]}`);
    });

    document.addEventListener('mouseup', () => {
        if (isPanning) {
            isPanning = false;
            svgElement.style.cursor = 'grab';
            // 更新originalViewBox以便下次拖拽基于新的位置
            originalViewBox = svgElement.getAttribute('viewBox').split(' ').map(Number);
        }
    });

    svgElement.addEventListener('wheel', (e) => {
        e.preventDefault();
        const scaleAmount = 0.1;
        const currentViewBox = svgElement.getAttribute('viewBox').split(' ').map(Number);
        let [vx, vy, vw, vh] = currentViewBox;

        const svgRect = svgElement.getBoundingClientRect();
        // 计算鼠标在SVG坐标系中的位置
        const mouseX = e.clientX - svgRect.left;
        const mouseY = e.clientY - svgRect.top;
        
        // 将鼠标位置转换为SVG内部坐标
        const svgX = vx + (mouseX / svgRect.width) * vw;
        const svgY = vy + (mouseY / svgRect.height) * vh;

        if (e.deltaY < 0) { // 放大
            vw *= (1 - scaleAmount);
            vh *= (1 - scaleAmount);
        } else { // 缩小
            vw *= (1 + scaleAmount);
            vh *= (1 + scaleAmount);
        }
        // 调整vx, vy以保持鼠标指向的点在屏幕上的位置不变
        vx = svgX - (mouseX / svgRect.width) * vw;
        vy = svgY - (mouseY / svgRect.height) * vh;

        svgElement.setAttribute('viewBox', `${vx} ${vy} ${vw} ${vh}`);
        originalViewBox = [vx, vy, vw, vh]; // 更新基础 viewBox
    });

    // 初始设置光标
    svgElement.style.cursor = 'grab';
});

// 添加一个active-node的CSS样式
const styleSheet = document.styleSheets[0]; // 获取第一个样式表
styleSheet.insertRule(`
.node.active-node rect {
    stroke: #feca57;
    stroke-width: 3px;
    filter: drop-shadow(0px 0px 15px #feca57);
}
`, styleSheet.cssRules.length);