const express = require("express");
const app = express();
const port = 3000;

app.use(express.json());

// Генерация случайных данных
function getRandomNumber(min, max, decimal = 0) {
    return (Math.random() * (max - min) + min).toFixed(decimal);
}

// Заглушка пользователя
const userProfile = {
    user_id: 10129,
    email: "user@whoopmock.com",
    first_name: "Test",
    last_name: "User",
};

// Заглушка цикла
const getCycle = (id) => ({
    id,
    user_id: userProfile.user_id,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    start: new Date(new Date() - 86400000).toISOString(),
    end: new Date().toISOString(),
    timezone_offset: "-05:00",
    score_state: "SCORED",
    score: {
        strain: getRandomNumber(2, 18, 2),
        kilojoule: getRandomNumber(5000, 10000, 2),
        average_heart_rate: getRandomNumber(55, 160),
        max_heart_rate: getRandomNumber(120, 190),
    },
});

// Заглушка восстановления
const getRecovery = () => ({
    cycle_id: 93845,
    sleep_id: 10235,
    user_id: userProfile.user_id,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    score_state: "SCORED",
    score: {
        user_calibrating: false,
        recovery_score: getRandomNumber(20, 100),
        resting_heart_rate: getRandomNumber(40, 80),
        hrv_rmssd_milli: getRandomNumber(20, 100, 2),
        spo2_percentage: getRandomNumber(90, 100, 2),
        skin_temp_celsius: getRandomNumber(32, 37, 1),
    },
});

// Заглушка сна
const getSleep = (id) => ({
    id,
    user_id: userProfile.user_id,
    created_at: new Date().toISOString(),
    updated_at: new Date().toISOString(),
    start: new Date(new Date() - 36000000).toISOString(),
    end: new Date().toISOString(),
    timezone_offset: "-05:00",
    nap: false,
    score_state: "SCORED",
    score: {
        stage_summary: {
            total_in_bed_time_milli: getRandomNumber(20000000, 40000000),
            total_awake_time_milli: getRandomNumber(500000, 3000000),
            total_light_sleep_time_milli: getRandomNumber(10000000, 20000000),
            total_slow_wave_sleep_time_milli: getRandomNumber(4000000, 8000000),
            total_rem_sleep_time_milli: getRandomNumber(4000000, 9000000),
            sleep_cycle_count: getRandomNumber(3, 6),
            disturbance_count: getRandomNumber(5, 20),
        },
        respiratory_rate: getRandomNumber(14, 20, 2),
        sleep_performance_percentage: getRandomNumber(70, 100),
        sleep_efficiency_percentage: getRandomNumber(80, 98, 2),
    },
});

// **Эндпоинты API**

// ✅ Профиль пользователя
app.get("/v1/user/profile/basic", (req, res) => {
    res.json(userProfile);
});

// ✅ Получение списка циклов
app.get("/v1/cycle", (req, res) => {
    res.json({ records: [getCycle(1), getCycle(2)], next_token: "next123" });
});

// ✅ Получение конкретного цикла
app.get("/v1/cycle/:cycleId", (req, res) => {
    res.json(getCycle(req.params.cycleId));
});

// ✅ Получение списка восстановлений
app.get("/v1/recovery", (req, res) => {
    res.json({ records: [getRecovery()], next_token: null });
});

// ✅ Получение списка сна
app.get("/v1/activity/sleep", (req, res) => {
    res.json({ records: [getSleep(1), getSleep(2)], next_token: null });
});

// ✅ Получение конкретного сна
app.get("/v1/activity/sleep/:sleepId", (req, res) => {
    res.json(getSleep(req.params.sleepId));
});

// Запуск сервера
app.listen(port, () => {
    console.log(`✅ Mock Whoop API запущен на http://localhost:${port}`);
});