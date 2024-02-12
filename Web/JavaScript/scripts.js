document.addEventListener("DOMContentLoaded", function(event) {
    const container = document.getElementById('container');
    const colors = ['#ff0000', '#00ff00', '#0000ff', '#ffff00', '#ff00ff', '#00ffff', '#ff8000', '#008000', '#800080', '#800000', '#008080', '#808000', '#808080', '#000080', '#800000'];
    for (let i = 0; i < 15; i++) {
        const ball = document.createElement('div');
        ball.classList.add('ball');
        ball.style.backgroundColor = colors[Math.floor(Math.random() * colors.length)];
        ball.style.top = Math.random() * (container.offsetHeight - 20) + 'px';
        ball.style.left = Math.random() * (container.offsetWidth - 20) + 'px';
        container.appendChild(ball);
    }
});

document.getElementById('button').addEventListener('click', function() {
    const balls = document.querySelectorAll('.ball');
    balls.forEach(ball => {
        const angle = Math.random() * Math.PI * 2;
        const speed = Math.random() * 5 + 2;

        function moveBall() {
            let x = parseFloat(ball.style.left);
            let y = parseFloat(ball.style.top);

            x += Math.cos(angle) * speed;
            y += Math.sin(angle) * speed;

            if (x < 0 || x > container.offsetWidth - 20) {
                angle = Math.PI - angle;
                x = Math.max(0, Math.min(x, container.offsetWidth - 20));
            }
            if (y < 0 || y > container.offsetHeight - 20) {
                angle = -angle;
                y = Math.max(0, Math.min(y, container.offsetHeight - 20));
            }

            ball.style.left = x + 'px';
            ball.style.top = y + 'px';

            requestAnimationFrame(moveBall);
        }

        moveBall();
    });
});

let count = 60;
document.getElementById('startButton').addEventListener('click', function() {
    const startButton = document.getElementById('startButton');
    startButton.disabled = true;
    const counter = document.getElementById('counter');
    const interval = setInterval(() => {
        count--;
        counter.innerText = count;
        if (count === 30) {
            alert("Тебе нужно ускориться!");
        }
        if (count === 0) {
            clearInterval(interval);
            startButton.disabled = false;
        }
    }, 1000);
});