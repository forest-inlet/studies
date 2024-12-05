<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <title>venus simulator</title>
    <style>
        *{
            margin: 0;
            padding: 0;
        }

        body{
            overflow: hidden;
        }

        div#settings{
            background-color: white;
            padding: 10px;
            border-radius: 10px;
            width: 170px;
            transform: scale(var(--scale));
            transform-origin: 100% 0%;
            position: fixed;
            top: 10px;
            right: 10px;
        }

        .small{
            position: fixed;
            top: 10px;
            left: 10px;
            border: 1px solid white;
        }
    </style>
    <script src="https://code.jquery.com/jquery-3.6.0.min.js"></script>
    <script src="https://unpkg.com/three@0.137.4/build/three.min.js"></script>
</head>
<body>
    <canvas id="earth"></canvas>
    <canvas id="top" class="small"></canvas>
    <div id="settings">
        <label>
            <input type="checkbox" id="info" checked>
            説明を表示
        </label><br>
        位置<br>
        <button id="left" class="sousa"><</button>
        <input type="range" max="360" min="-1" value="0" id="rad">
        <button id="right" class="sousa">></button>
    </div>
    <script>
        let width = window.innerWidth
        let height = window.innerHeight
        let leftInterval, leftTimeout, rightInterval, rightTimeout

        const earthView = () => {
            const earthRenderer = new THREE.WebGLRenderer({
                canvas: document.querySelector('canvas#earth')
            })
            earthRenderer.setSize(width, height)

            const topRenderer = new THREE.WebGLRenderer({
                canvas: document.querySelector('canvas#top')
            })
            topRenderer.setSize(width * 0.25, height * 0.25)

            const scene = new THREE.Scene()

            const earthGeometry = new THREE.SphereGeometry(50, 64, 64)
            const earthMaterial = new THREE.MeshLambertMaterial({color: 0x8888ff})
            const earth = new THREE.Mesh(earthGeometry, earthMaterial)
            earth.position.set(500, 0, 0)
            scene.add(earth)

            const venusGeometry = new THREE.SphereGeometry(50, 64, 64)
            const venusMaterial = new THREE.MeshLambertMaterial({color: 0xffff88})
            const venus = new THREE.Mesh(venusGeometry, venusMaterial)
            venus.position.set(300, 0, 0)
            scene.add(venus)

            const light = new THREE.PointLight(0xffffff, 2, 500, 0)
            light.position.set(0, 0, 0)
            scene.add(light)

            const sunGeometry = new THREE.SphereGeometry(100, 64, 64)
            const sunMaterial = new THREE.MeshBasicMaterial({color: 0xffff00})
            const sun = new THREE.Mesh(sunGeometry, sunMaterial)
            sun.position.copy(light.position)
            scene.add(sun)

            const earthCamera = new THREE.PerspectiveCamera(90, width / height)
            earthCamera.position.set(earth.position.x, 100, earth.position.z)

            const topCamera = new THREE.OrthographicCamera(
                600, -600,
                -600 / (width / height),
                600 / (width / height)
            )
            topCamera.position.set(0, 1000, 0)
            topCamera.lookAt(0, 0, 0)

            function animate() {
                let rad = 360 - $('input#rad').val()
                let x = Math.cos(rad * (Math.PI / 180)) * 300
                let z = Math.sin(rad * (Math.PI / 180)) * 300
                venus.position.set(x, 0, z)
                earthCamera.lookAt(venus.position)
                if ($('canvas#earth').hasClass('small')) {
                    earthRenderer.setSize(width * 0.25, height * 0.25)
                    topRenderer.setSize(width, height)
                } else {
                    earthRenderer.setSize(width, height)
                    topRenderer.setSize(width * 0.25, height * 0.25)
                }
                earthRenderer.render(scene, earthCamera)
                topRenderer.render(scene, topCamera)
                requestAnimationFrame(animate)
            }
            animate()

            $('canvas').on('click', function() {
                $(this).removeClass('small')
                $('canvas').not(this).addClass('small')
            })

            $(window).on('resize', () => {
                width = window.innerWidth
                height = window.innerHeight
                
                if (1200 / (width / height) >= 700) {
                    topCamera.left = 600
                    topCamera.right = -600
                    topCamera.top = -600 / (width / height)
                    topCamera.bottom = 600 / (width / height)
                } else {
                    topCamera.left = 350 * (width / height)
                    topCamera.right = -350 * (width / height)
                    topCamera.top = -350
                    topCamera.bottom = 350
                }
                topCamera.updateProjectionMatrix()

                earthCamera.aspect = width / height
                earthCamera.updateProjectionMatrix()
            })

            $(window).resize()
        }

        $(window).ready(earthView)

        $(window).on('resize', () => {
            const scale = (window.innerWidth * 0.25) / 200
            $(':root').css('--scale', scale)
        })

        $('input#rad').on('change', function() {
            if ($(this).val() < 0) {
                $(this).val(359)
            } else if ($(this).val() > 359) {
                $(this).val(0)
            }
        })

        $('button#left').on('mousedown touchstart', () => {
            let nun = $('input#rad').val()
            nun --
            $('input#rad').val(nun)
            $('input#rad').change()

            leftTimeout = setTimeout(() => {
                leftInterval = setInterval(() => {
                    let nun = $('input#rad').val()
                    nun --
                    $('input#rad').val(nun)
                    $('input#rad').change()
                }, 25)
            }, 500)
        })
        $('button#left').on('mouseup mouseleave touchend thouchcancel', () => {
            clearInterval(leftInterval)
            clearTimeout(leftTimeout)
        })

        $('button#right').on('mousedown touchstart', () => {
            let nun = $('input#rad').val()
            nun ++
            $('input#rad').val(nun)
            $('input#rad').change()

            rightTimeout = setTimeout(() => {
                rightInterval = setInterval(() => {
                    let nun = $('input#rad').val()
                    nun ++
                    $('input#rad').val(nun)
                    $('input#rad').change()
                }, 25)
            }, 500)
        })
        $('button#right').on('mouseup mouseleave touchend thouchcancel', () => {
            clearInterval(rightInterval)
            clearTimeout(rightTimeout)
        })
    </script>
</body>
</html>
