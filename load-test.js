import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  stages: [
    { duration: '5s', target: 150 },  // Разгон: за 5 секунд поднимаем нагрузку до 150 юзеров
    { duration: '20s', target: 150 }, // Держим удар: 150 активных пользователей бомбардируют шлюз 20 секунд
    { duration: '5s', target: 0 },    // Спад: завершаем тест
  ],
};

export default function () {
  const params = {
    headers: { 'Content-Type': 'application/json' },
  };

  // Бьем по шлюзу гейтвея (порт 5555), заставляя его маршрутизировать трафик на микросервисы
  http.get('http://127.0.0.1:5555/login', params);
 
  
  sleep(0.05); // Небольшая пауза в 50 миллисекунд между кликами каждого виртуального игрока
}
