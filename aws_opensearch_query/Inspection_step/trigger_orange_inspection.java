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

    // sensors 배열에서 검수 공정 센서 값 추출
    for (def item : sensors) {
        if (item.type == "weig") { weig = item.value; }
        if (item.type == "torq") { torq = item.value; }
    }

    // --- [점수 계산: Inspection 공정 기준] ---
    // 기본값(Green)은 1점
    int score_weig = 1;
    int score_torq = 1;
    int score_phot = 1; // 포토 센서는 기본 점수 부여

    // 1. 무게(weig) 점수 산정
    // Red (10점): 400 미만 or 1700 초과
    if (weig < 400 || weig > 1700) { 
        score_weig = 10; 
    }
    // Yellow/Caution (3점): 400~999 or 1101~1700
    // Score표의 박스 무게 Orange 점수(3점)를 적용하여 가중치 부여
    else if ((weig >= 400 && weig <= 999) || (weig >= 1101 && weig <= 1700)) { 
        score_weig = 3; 
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

    // --- [Orange 판별] ---
    // 조건 1: 총점이 7점 이상 (Orange 기준)
    // 조건 2: 총점이 10점 미만 (Red 상태 제외)
    if (total_score >= 7 && total_score < 10) {
        return true; 
    }
}

return false;