const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const path = require('path');

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
    maxHttpBufferSize: 1e8 // 100MB for image transfers
});

app.use(express.static(path.join(__dirname, 'public')));

io.on('connection', (socket) => {
    console.log('A user connected:', socket.id);

    // Forward QR data from mobile to windows
    socket.on('scan-qr', (data) => {
        console.log('QR Scanned:', data);
        io.emit('qr-received', data);
    });

    // Forward Image data from mobile to windows
    socket.on('scan-image', (data) => {
        console.log('Image received from mobile');
        io.emit('image-received', data);
    });

    socket.on('disconnect', () => {
        console.log('User disconnected:', socket.id);
    });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on http://localhost:${PORT}`);
    console.log(`Access mobile view at http://<your-ip>:${PORT}/mobile.html`);
});
