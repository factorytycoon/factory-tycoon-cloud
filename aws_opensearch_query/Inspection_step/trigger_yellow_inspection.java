// 1. 데이터가 없으면 종료
if (ctx.results[0].hits.total.value == 0) {
    return false;
}

// 2. 검색된 모든 데이터 순회
for (def hit : ctx.results[0].hits.hits) {
    
    // --- [데이터 파싱] ---
    def source = hit._source;
    def sensors = source.sensors;

    // 변수 초기화
    def weig = 0.0;
    def torq = 0.0;
    // phot는 점수에 영향이 없거나(0점), Orange(6점)로 넘어가므로 기본값 0으로 처리

    // sensors 배열에서 검수 공정 센서 값 추출
    for (def item : sensors) {
        if (item.type == "weig") { weig = item.value; }
        if (item.type == "torq") { torq = item.value; }
    }

    // --- [점수 계산: Inspection 공정 기준] ---
    // 기본값: 무게(1), 토크(1), 포토(0) = 2점
    int score_weig = 1;
    int score_torq = 1;
    int score_phot = 1; // Score표 기준 포토센서 정상은 0점

    // 1. 무게(weig) 점수 산정
    // Red (10점): 400 미만 or 1700 초과
    if (weig < 400 || weig > 1700) { 
        score_weig = 10; 
    }
    // Yellow/Caution (2점): 400~999 or 1101~1700
    // Score표의 Yellow 점수(2점)를 적용하여 총점 6점을 맞춤
    else if ((weig >= 400 && weig <= 999) || (weig >= 1101 && weig <= 1700)) { 
        score_weig = 2; 
    }

    // 2. 모터 토크(torq) 점수 산정
    // Red (10점): 5 미만 or 55 초과
    if (torq < 5 || torq > 55) { 
        score_torq = 10; 
    }
    // Orange (4점): 46 ~ 55 (Score표 기준)
    else if (torq >= 46 && torq <= 55) { 
        score_torq = 4; 
    }
    // Yellow (2점): 30 ~ 45 (Score표 기준)
    else if (torq >= 30 && torq <= 45) { 
        score_torq = 2; 
    }

    // 총점 합산
    int total_score = score_weig + score_torq + score_phot;

    // --- [Yellow 판별] ---
    // 조건 1: 총점이 6점 이상 (Yellow 기준)
    // 조건 2: 총점이 7점 미만 (Orange 기준 미만)
    if (total_score >= 6 && total_score < 7) {
        return true; 
    }
}

return false;